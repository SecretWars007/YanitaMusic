/**
 * audio_processor.cpp - Procesador de audio nativo para Yanita Music
 *
 * Pipeline DSP completo:
 * 1. Decodificación MP3 (minimp3 header-only)
 * 2. Resampling a 16kHz mono
 * 3. STFT con ventana Hann
 * 4. Banco de filtros Mel (229 bins)
 * 5. Normalización logarítmica
 *
 * Exporta funciones C para ser consumidas via dart:ffi
 */

#define MINIMP3_IMPLEMENTATION
#include "minimp3.h"
#include "minimp3_ex.h"

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <cmath>
#include <vector>
#include <string>
#include <algorithm>
#include <android/log.h>

#define LOG_TAG "AudioProcessorFFI_Native"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ─── Constantes del pipeline DSP ───
static const int TARGET_SAMPLE_RATE = 16000;
static const int FFT_SIZE = 2048;
static const int HOP_SIZE = 160;  // 10ms a 16kHz
static const int NUM_MEL_BINS = 229;
static const float MEL_FMIN = 30.0f;
static const float MEL_FMAX = 8000.0f;
static const float PI = 3.14159265358979323846f;

// Variable global para último error
static std::string g_last_error = "";

// ─── Funciones auxiliares DSP ───

/**
 * Convierte frecuencia Hz a escala Mel.
 */
static float hz_to_mel(float hz) {
    return 2595.0f * log10f(1.0f + hz / 700.0f);
}

/**
 * Convierte escala Mel a frecuencia Hz.
 */
static float mel_to_hz(float mel) {
    return 700.0f * (powf(10.0f, mel / 2595.0f) - 1.0f);
}

/**
 * Resamplea audio de sample_rate original a TARGET_SAMPLE_RATE.
 * Usa interpolación lineal simple.
 */
static std::vector<float> resample(const int16_t* samples, int num_samples,
                                    int original_sr, int num_channels) {
    // Primero convertir a mono float normalizado
    std::vector<float> mono(num_samples / num_channels);
    for (int i = 0; i < (int)mono.size(); i++) {
        float sum = 0.0f;
        for (int ch = 0; ch < num_channels; ch++) {
            sum += samples[i * num_channels + ch] / 32768.0f;
        }
        mono[i] = sum / num_channels;
    }

    if (original_sr == TARGET_SAMPLE_RATE) {
        return mono;
    }

    // Resampleo por interpolación lineal
    double ratio = (double)original_sr / (double)TARGET_SAMPLE_RATE;
    int output_len = (int)((double)mono.size() / ratio);
    std::vector<float> resampled(output_len);

    for (int i = 0; i < output_len; i++) {
        double src_idx = i * ratio;
        int idx0 = (int)src_idx;
        int idx1 = std::min(idx0 + 1, (int)mono.size() - 1);
        float frac = (float)(src_idx - idx0);
        resampled[i] = mono[idx0] * (1.0f - frac) + mono[idx1] * frac;
    }

    return resampled;
}

/**
 * Genera ventana Hann de tamaño dado.
 */
static std::vector<float> hann_window(int size) {
    std::vector<float> window(size);
    for (int i = 0; i < size; i++) {
        window[i] = 0.5f * (1.0f - cosf(2.0f * PI * i / (size - 1)));
    }
    return window;
}

/**
 * FFT in-place simple (Cooley-Tukey radix-2 DIT).
 * Trabaja sobre arrays de complejos representados como pares (real, imag).
 */
static void fft_inplace(float* real, float* imag, int n) {
    // Bit-reversal permutation
    for (int i = 1, j = 0; i < n; i++) {
        int bit = n >> 1;
        for (; j & bit; bit >>= 1) {
            j ^= bit;
        }
        j ^= bit;
        if (i < j) {
            std::swap(real[i], real[j]);
            std::swap(imag[i], imag[j]);
        }
    }

    // Cooley-Tukey
    for (int len = 2; len <= n; len <<= 1) {
        float ang = -2.0f * PI / len;
        float w_real = cosf(ang);
        float w_imag = sinf(ang);
        for (int i = 0; i < n; i += len) {
            float cur_real = 1.0f, cur_imag = 0.0f;
            for (int j = 0; j < len / 2; j++) {
                float u_real = real[i + j];
                float u_imag = imag[i + j];
                float v_real = real[i + j + len / 2] * cur_real -
                               imag[i + j + len / 2] * cur_imag;
                float v_imag = real[i + j + len / 2] * cur_imag +
                               imag[i + j + len / 2] * cur_real;
                real[i + j] = u_real + v_real;
                imag[i + j] = u_imag + v_imag;
                real[i + j + len / 2] = u_real - v_real;
                imag[i + j + len / 2] = u_imag - v_imag;
                float new_cur_real = cur_real * w_real - cur_imag * w_imag;
                cur_imag = cur_real * w_imag + cur_imag * w_real;
                cur_real = new_cur_real;
            }
        }
    }
}

/**
 * Calcula el espectro de potencia de forma in-place para minimizar allocations.
 * Se pasan los vectores de variables reciclados por referencia.
 */
static void compute_power_spectrum(
    const float* audio, int start, int fft_size,
    const std::vector<float>& window, int audio_len,
    std::vector<float>& real_part, std::vector<float>& imag_part,
    std::vector<float>& power_spec) {

    int spec_size = fft_size / 2 + 1;

    // Reset arrays iterando sobre elements en vez de re-alojar memoria
    std::fill(real_part.begin(), real_part.end(), 0.0f);
    std::fill(imag_part.begin(), imag_part.end(), 0.0f);

    // Aplicar ventana
    for (int i = 0; i < fft_size; i++) {
        int idx = start + i;
        if (idx >= 0 && idx < audio_len) {
            real_part[i] = audio[idx] * window[i];
        }
    }

    // FFT
    fft_inplace(real_part.data(), imag_part.data(), fft_size);

    // Calcular potencia espectral: Magnitud al cuadrado
    // Evita la penalidad de procesamiento intensivo matemático de `sqrtf`
    for (int i = 0; i < spec_size; i++) {
        power_spec[i] = (real_part[i] * real_part[i]) + (imag_part[i] * imag_part[i]);
    }
}

// ─── Estructuras para optimización ───
struct MelFilter {
    int start_bin;
    int end_bin;
    std::vector<float> weights;
};

/**
 * Crea el banco de filtros Mel triangulares de forma dispersa (sparse).
 * Esto evita procesar miles de ceros innecesarios en cada frame.
 */
static std::vector<MelFilter> create_sparse_mel_filterbank(
    int num_mel_bins, int fft_size, int sample_rate,
    float fmin, float fmax) {

    int spec_size = fft_size / 2 + 1;
    float mel_min = hz_to_mel(fmin);
    float mel_max = hz_to_mel(fmax);

    std::vector<float> mel_points(num_mel_bins + 2);
    for (int i = 0; i < num_mel_bins + 2; i++) {
        mel_points[i] = mel_min + (mel_max - mel_min) * (float)i / (num_mel_bins + 1);
    }

    std::vector<int> fft_bins(num_mel_bins + 2);
    for (int i = 0; i < num_mel_bins + 2; i++) {
        float hz = mel_to_hz(mel_points[i]);
        fft_bins[i] = (int)floorf((float)(fft_size + 1) * hz / (float)sample_rate);
        if (fft_bins[i] >= spec_size) fft_bins[i] = spec_size - 1;
    }

    std::vector<MelFilter> filterbank(num_mel_bins);

    for (int m = 0; m < num_mel_bins; m++) {
        int f_left = fft_bins[m];
        int f_center = fft_bins[m + 1];
        int f_right = fft_bins[m + 2];

        filterbank[m].start_bin = f_left;
        filterbank[m].end_bin = f_right;
        filterbank[m].weights.resize(f_right - f_left + 1, 0.0f);

        for (int k = f_left; k <= f_right; k++) {
            float weight = 0.0f;
            if (k >= f_left && k <= f_center && f_center != f_left) {
                weight = (float)(k - f_left) / (float)(f_center - f_left);
            } else if (k > f_center && k <= f_right && f_right != f_center) {
                weight = (float)(f_right - k) / (float)(f_right - f_center);
            }
            filterbank[m].weights[k - f_left] = weight;
        }
    }

    return filterbank;
}

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Procesa un archivo MP3 y genera su espectrograma Mel.
 *
 * @param file_path   Ruta absoluta al archivo de audio
 * @param out_frames  [OUT] Número de frames generados
 * @param out_mel_bins [OUT] Bins Mel (siempre 229)
 * @param out_duration [OUT] Duración en segundos
 * @return Puntero al buffer plano de floats [frames * mel_bins], o nullptr si error
 */
__attribute__((visibility("default"))) __attribute__((used))
float* process_audio_file(const char* file_path, int32_t* out_frames,
                          int32_t* out_mel_bins, double* out_duration) {
    LOGI("Procesando archivo: %s", file_path);

    if (file_path == nullptr || out_frames == nullptr ||
        out_mel_bins == nullptr || out_duration == nullptr) {
        g_last_error = "Punteros invalidos proporcionados al modulo nativo.";
        LOGE("%s", g_last_error.c_str());
        return nullptr;
    }

    // ─── Paso 1: Decodificar MP3 con minimp3 ───
    mp3dec_t mp3d;
    mp3dec_file_info_t info;
    memset(&info, 0, sizeof(info));

    int result = mp3dec_load(&mp3d, file_path, &info, NULL, NULL);
    if (result != 0 || info.samples == 0 || info.buffer == nullptr) {
        g_last_error = "Error al decodificar el archivo de audio. "
                       "Asegurese de que es un archivo MP3 valido.";
        LOGE("mp3dec_load error: %d, samples: %zu", result, info.samples);
        if (info.buffer) free(info.buffer);
        return nullptr;
    }

    LOGI("MP3 decodificado: %zu muestras, %d Hz, %d canales",
         info.samples, info.hz, info.channels);

    // ─── Paso 2: Resamplear a 16kHz mono ───
    int total_samples = (int)info.samples;
    std::vector<float> audio = resample(info.buffer, total_samples,
                                         info.hz, info.channels);
    free(info.buffer);  // Liberar buffer de minimp3

    int audio_len = (int)audio.size();
    double duration = (double)audio_len / TARGET_SAMPLE_RATE;

    LOGI("Audio resampleado: %d muestras, %.2f segundos", audio_len, duration);

    if (audio_len < FFT_SIZE) {
        g_last_error = "Audio demasiado corto para procesar (menos de "
                       "128ms). Use un archivo mas largo.";
        LOGE("%s", g_last_error.c_str());
        return nullptr;
    }

    // ─── Paso 3: Generar ventana Hann ───
    std::vector<float> window = hann_window(FFT_SIZE);

    // ─── Paso 4: Crear banco de filtros Mel disperso ───
    auto filterbank = create_sparse_mel_filterbank(
        NUM_MEL_BINS, FFT_SIZE, TARGET_SAMPLE_RATE, MEL_FMIN, MEL_FMAX);

    // ─── Paso 5: STFT + Mel filterbank frame a frame ───
    int num_frames = (audio_len - FFT_SIZE) / HOP_SIZE + 1;
    if (num_frames <= 0) num_frames = 1;

    LOGI("Generando %d frames de espectrograma Mel (Optimizado)", num_frames);

    // Alojar buffer de salida [num_frames x NUM_MEL_BINS]
    int total_elements = num_frames * NUM_MEL_BINS;
    float* output = (float*)malloc(total_elements * sizeof(float));
    if (output == nullptr) {
        g_last_error = "Error al alojar memoria para el espectrograma.";
        LOGE("%s", g_last_error.c_str());
        return nullptr;
    }

    // [SENIOR OPTIMIZATION]: Pre-alojar buffers para el hot-loop
    std::vector<float> real_part(FFT_SIZE, 0.0f);
    std::vector<float> imag_part(FFT_SIZE, 0.0f);
    int spec_size = FFT_SIZE / 2 + 1;
    std::vector<float> power_spec(spec_size, 0.0f);

    for (int frame = 0; frame < num_frames; frame++) {
        int start = frame * HOP_SIZE;

        // Obtener espectro de potencia in-place con arrays reutilizados
        compute_power_spectrum(
            audio.data(), start, FFT_SIZE, window, audio_len,
            real_part, imag_part, power_spec);

        // Aplicar filtros Mel dispersos + log
        for (int m = 0; m < NUM_MEL_BINS; m++) {
            float energy = 0.0f;
            const auto& filter = filterbank[m];
            
            // OPTIMIZACIÓN SPRASE: Solo iterar sobre el rango relevante del filtro
            // reduce ~80% de las multiplicaciones por frame.
            for (int k = filter.start_bin; k <= filter.end_bin; k++) {
                energy += power_spec[k] * filter.weights[k - filter.start_bin];
            }
            
            // Log-mel: log(max(energy, 1e-10))
            output[frame * NUM_MEL_BINS + m] = logf(fmaxf(energy, 1e-10f));
        }
    }

    // ─── Paso 6: Normalización global ───
    float global_min = output[0], global_max = output[0];
    for (int i = 1; i < total_elements; i++) {
        if (output[i] < global_min) global_min = output[i];
        if (output[i] > global_max) global_max = output[i];
    }
    float range = global_max - global_min;
    if (range > 1e-6f) {
        for (int i = 0; i < total_elements; i++) {
            output[i] = (output[i] - global_min) / range;
        }
    }

    *out_frames = num_frames;
    *out_mel_bins = NUM_MEL_BINS;
    *out_duration = duration;

    LOGI("Espectrograma Mel generado: %d frames x %d bins, "
         "duracion: %.2fs", num_frames, NUM_MEL_BINS, duration);
    return output;
}

/**
 * Libera la memoria alojada para el buffer de espectrograma.
 */
__attribute__((visibility("default"))) __attribute__((used))
void free_buffer(float* buffer) {
    if (buffer != nullptr) {
        free(buffer);
        LOGI("Memoria del buffer de espectrograma liberada.");
    }
}

/**
 * Retorna el último mensaje de error.
 */
__attribute__((visibility("default"))) __attribute__((used))
const char* get_last_error() {
    return g_last_error.c_str();
}

#ifdef __cplusplus
}
#endif

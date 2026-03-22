#include "audio_utils.hpp"

#define MINIMP3_IMPLEMENTATION
#include "minimp3.h"
#include "minimp3_ex.h"

#include <string>
#include <vector>
#include <chrono>
#include <cstring>
#include <android/log.h>

#define LOG_TAG "YanitaNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

static std::string g_last_error = "";

extern "C" {

/**
 * Procesa un archivo de audio y genera su espectrograma Mel.
 * Exportado con visibilidad por defecto para FFI.
 */
__attribute__((visibility("default"))) 
float* process_audio_file(const char* file_path, int32_t* out_frames,
                          int32_t* out_mel_bins, double* out_duration) {
    auto start_total = std::chrono::high_resolution_clock::now();
    LOGI(">>> INICIO FFI: %s", file_path ? file_path : "NULL");

    if (file_path == nullptr || out_frames == nullptr ||
        out_mel_bins == nullptr || out_duration == nullptr) {
        g_last_error = "Punteros invalidos proporcionados al modulo nativo.";
        LOGE("Error: %s", g_last_error.c_str());
        return nullptr;
    }

    std::vector<float> audio;
    int original_sr = 0;
    int num_channels = 0;

    std::string path_str(file_path);
    bool is_wav = path_str.size() > 4 && 
                  path_str.substr(path_str.size() - 4) == ".wav";

    if (is_wav) {
        FILE* f = fopen(file_path, "rb");
        if (f) {
            char header[44];
            if (fread(header, 1, 44, f) == 44) {
                num_channels = *(uint16_t*)(header + 22);
                original_sr = *(uint32_t*)(header + 24);
                uint32_t data_size = *(uint32_t*)(header + 40);
                
                if (data_size > 0 && num_channels > 0 && num_channels <= 8) {
                    std::vector<int16_t> samples(data_size / 2);
                    size_t read_bytes = fread(samples.data(), 2, samples.size(), f);
                    if (read_bytes == samples.size()) {
                        audio = yanita::resample(samples.data(), (int)samples.size(), original_sr, num_channels);
                    }
                }
            }
            fclose(f);
        }
    }

    // Fallback a MP3
    if (audio.empty()) {
        mp3dec_t mp3d;
        mp3dec_file_info_t info;
        memset(&info, 0, sizeof(info));

        int result = mp3dec_load(&mp3d, file_path, &info, nullptr, nullptr);
        if (result == 0 && info.samples > 0 && info.buffer != nullptr) {
            audio = yanita::resample(info.buffer, (int)info.samples, info.hz, info.channels);
            free(info.buffer);
        } else {
            g_last_error = "Error al decodificar audio: " + std::to_string(result);
            if (info.buffer) free(info.buffer);
            return nullptr;
        }
    }

    int audio_len = (int)audio.size();
    if (audio_len < FFT_SIZE) {
        g_last_error = "Audio demasiado corto.";
        return nullptr;
    }

    double duration = (double)audio_len / TARGET_SAMPLE_RATE;
    std::vector<float> window = yanita::hann_window(FFT_SIZE);
    auto filterbank = yanita::create_sparse_mel_filterbank(NUM_MEL_BINS, FFT_SIZE, TARGET_SAMPLE_RATE, MEL_FMIN, MEL_FMAX);

    int num_frames = (audio_len - FFT_SIZE) / HOP_SIZE + 1;
    if (num_frames <= 0) num_frames = 1;

    size_t total_elements = (size_t)num_frames * NUM_MEL_BINS;
    float* output = (float*)malloc(total_elements * sizeof(float));
    if (output == nullptr) {
        g_last_error = "Fallo de memoria.";
        return nullptr;
    }

    std::vector<float> real_part(FFT_SIZE, 0.0f);
    std::vector<float> imag_part(FFT_SIZE, 0.0f);
    int spec_size = FFT_SIZE / 2 + 1;
    std::vector<float> power_spec(spec_size, 0.0f);

    auto start_dsp = std::chrono::high_resolution_clock::now();
    for (int frame = 0; frame < num_frames; frame++) {
        int start = frame * HOP_SIZE;
        yanita::compute_power_spectrum(audio.data(), start, FFT_SIZE, window, audio_len, real_part, imag_part, power_spec);

        for (int m = 0; m < NUM_MEL_BINS; m++) {
            float energy = 0.0f;
            const auto& filter = filterbank[m];
            for (int k = filter.start_bin; k <= filter.end_bin; k++) {
                energy += power_spec[k] * filter.weights[k - filter.start_bin];
            }
            output[frame * NUM_MEL_BINS + m] = std::log(std::max(energy, 1e-10f));
        }
    }

    // Normalización
    float g_min = output[0], g_max = output[0];
    for (size_t i = 1; i < total_elements; i++) {
        if (output[i] < g_min) g_min = output[i];
        if (output[i] > g_max) g_max = output[i];
    }
    float range = g_max - g_min;
    if (range > 1e-7f) {
        for (size_t i = 0; i < total_elements; i++) {
            output[i] = (output[i] - g_min) / range;
        }
    }

    auto end_total = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end_total - start_total;

    *out_frames = num_frames;
    *out_mel_bins = NUM_MEL_BINS;
    *out_duration = duration;

    LOGI("<<< FIN FFI: Espectrograma generado en %.3f seg", elapsed.count());
    return output;
}

__attribute__((visibility("default")))
void free_buffer(float* buffer) {
    if (buffer != nullptr) {
        free(buffer);
    }
}

__attribute__((visibility("default")))
const char* get_last_error() {
    return g_last_error.c_str();
}

} // extern "C"

#include "audio_utils.hpp"
#include <cmath>
#include <algorithm>
#include <android/log.h>

#define LOG_TAG "YanitaDSP"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

namespace yanita {

float hz_to_mel(float hz) {
    return 2595.0f * std::log10(1.0f + hz / 700.0f);
}

float mel_to_hz(float mel) {
    return 700.0f * (std::pow(10.0f, mel / 2595.0f) - 1.0f);
}

std::vector<float> resample(const int16_t* samples, int num_samples, int original_sr, int num_channels) {
    if (num_samples <= 0 || original_sr <= 0 || num_channels <= 0) {
        LOGE("Parámetros de resample invalidos: samples=%d, sr=%d, channels=%d", num_samples, original_sr, num_channels);
        return {};
    }

    int mono_len = num_samples / num_channels;
    std::vector<float> mono(mono_len);
    for (int i = 0; i < mono_len; i++) {
        float sum = 0.0f;
        for (int ch = 0; ch < num_channels; ch++) {
            sum += samples[i * num_channels + ch] / 32768.0f;
        }
        mono[i] = sum / num_channels;
    }

    if (original_sr == TARGET_SAMPLE_RATE) {
        return mono;
    }

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

std::vector<float> hann_window(int size) {
    std::vector<float> window(size);
    for (int i = 0; i < size; i++) {
        window[i] = 0.5f * (1.0f - std::cos(2.0f * PI * i / (size - 1)));
    }
    return window;
}

void fft_inplace(float* real, float* imag, int n) {
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

    for (int len = 2; len <= n; len <<= 1) {
        float ang = -2.0f * PI / len;
        float w_real = std::cos(ang);
        float w_imag = std::sin(ang);
        for (int i = 0; i < n; i += len) {
            float cur_real = 1.0f, cur_imag = 0.0f;
            for (int j = 0; j < len / 2; j++) {
                float u_real = real[i + j];
                float u_imag = imag[i + j];
                float v_real = real[i + j + len / 2] * cur_real - imag[i + j + len / 2] * cur_imag;
                float v_imag = real[i + j + len / 2] * cur_imag + imag[i + j + len / 2] * cur_real;
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

std::vector<MelFilter> create_sparse_mel_filterbank(int num_mel_bins, int fft_size, int sample_rate, float fmin, float fmax) {
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
        fft_bins[i] = (int)std::floor((float)(fft_size + 1) * hz / (float)sample_rate);
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

void compute_power_spectrum(
    const float* audio, int start, int fft_size,
    const std::vector<float>& window, int audio_len,
    std::vector<float>& real_part, std::vector<float>& imag_part,
    std::vector<float>& power_spec) {

    int spec_size = fft_size / 2 + 1;

    std::fill(real_part.begin(), real_part.end(), 0.0f);
    std::fill(imag_part.begin(), imag_part.end(), 0.0f);

    for (int i = 0; i < fft_size; i++) {
        int idx = start + i;
        if (idx >= 0 && idx < audio_len) {
            real_part[i] = audio[idx] * window[i];
        }
    }

    fft_inplace(real_part.data(), imag_part.data(), fft_size);

    for (int i = 0; i < spec_size; i++) {
        power_spec[i] = (real_part[i] * real_part[i]) + (imag_part[i] * imag_part[i]);
    }
}

} // namespace yanita

#ifndef AUDIO_UTILS_HPP
#define AUDIO_UTILS_HPP

#include <vector>
#include <string>
#include <cstdint>

// ─── Constantes del pipeline DSP ───
const int TARGET_SAMPLE_RATE = 16000;
const int FFT_SIZE = 2048;
const int HOP_SIZE = 160;  // 10ms a 16kHz
const int NUM_MEL_BINS = 229;
const float MEL_FMIN = 30.0f;
const float MEL_FMAX = 8000.0f;
const float PI = 3.14159265358979323846f;

namespace yanita {

// Funciones DSP internas
float hz_to_mel(float hz);
float mel_to_hz(float mel);

std::vector<float> resample(const int16_t* samples, int num_samples, int original_sr, int num_channels);
std::vector<float> hann_window(int size);
void fft_inplace(float* real, float* imag, int n);

struct MelFilter {
    int start_bin;
    int end_bin;
    std::vector<float> weights;
};

std::vector<MelFilter> create_sparse_mel_filterbank(int num_mel_bins, int fft_size, int sample_rate, float fmin, float fmax);

void compute_power_spectrum(
    const float* audio, int start, int fft_size,
    const std::vector<float>& window, int audio_len,
    std::vector<float>& real_part, std::vector<float>& imag_part,
    std::vector<float>& power_spec);

} // namespace yanita

#endif // AUDIO_UTILS_HPP

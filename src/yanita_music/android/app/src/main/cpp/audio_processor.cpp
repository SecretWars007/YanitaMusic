#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <android/log.h>
#include <vector>
#include <string>

#define LOG_TAG "AudioProcessorFFI_Native"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#ifdef __cplusplus
extern "C" {
#endif

// Variable global estática para almacenar el último error
static std::string g_last_error = "";

// Definición de las funciones exportadas requeridas por audio_processor_ffi.dart

// Procesa un archivo de audio y retorna el espectrograma (puntero a buffer de floats)
__attribute__((visibility("default"))) __attribute__((used))
float* process_audio_file(const char* file_path, int32_t* out_frames, int32_t* out_mel_bins, double* out_duration) {
    LOGI("Procesando archivo: %s", file_path);
    
    if (file_path == nullptr || out_frames == nullptr || out_mel_bins == nullptr || out_duration == nullptr) {
        g_last_error = "Punteros invalidos proporcionados al modulo nativo.";
        LOGE("%s", g_last_error.c_str());
        return nullptr;
    }

    // AQUI IRÍA LA INTEGRACIÓN REAL CON MINIMP3 y KISSFFT
    // Para propositos del MVP, generaremos un tensor de dimensiones dummy
    // que simulan un espectrograma real, llenándolo con ceros.

    *out_frames = 100; // 100 frames (~3 segundos a hop size típico)
    *out_mel_bins = 229; // Típicamente usado por el modelo Onsets and Frames
    *out_duration = 3.0; // 3 segundos de duración simulada

    int total_elements = (*out_frames) * (*out_mel_bins);
    
    // Asignar memoria para el buffer plano de salida
    // Usamos calloc para inicializar con ceros (simulando silencio)
    float* buffer = (float*) calloc(total_elements, sizeof(float));
    
    if (buffer == nullptr) {
        g_last_error = "Error al alojar memoria para el espectrograma.";
        LOGE("%s", g_last_error.c_str());
        return nullptr;
    }
    
    // Rellenamos el buffer con ruido pequeño solo para el MVP
    for (int i = 0; i < total_elements; i++) {
        buffer[i] = ((float)rand() / RAND_MAX) * 0.1f; // Valores entre 0 y 0.1
    }

    LOGI("Procesamiento completado. Generados %d frames.", *out_frames);
    return buffer;
}

// Libera la memoria alojada previamente para el buffer
__attribute__((visibility("default"))) __attribute__((used))
void free_buffer(float* buffer) {
    if (buffer != nullptr) {
        free(buffer);
        LOGI("Memoria del buffer de espectrograma liberada.");
    }
}

// Retorna un puntero constante a la cadena del último error
__attribute__((visibility("default"))) __attribute__((used))
const char* get_last_error() {
    return g_last_error.c_str();
}

#ifdef __cplusplus
}
#endif

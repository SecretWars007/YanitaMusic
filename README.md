# 🎹 YANITA MUSIC – Transcripción Musical Automática (AMT)

<p align="center">
  <strong>MVP de aplicación móvil para transcripción musical automática de piano electrónico</strong>
</p>

> Proyecto de Maestría – Desarrollo siguiendo buenas prácticas SDLC  
> Flutter · Clean Architecture · BLoC · TFLite · SQLite · C++ FFI

---

## 📋 Tabla de Contenidos

1. [Descripción](#descripción)
2. [Arquitectura](#arquitectura)
3. [Requisitos Previos](#requisitos-previos)
4. [Instalación Paso a Paso](#instalación-paso-a-paso)
5. [Estructura del Proyecto](#estructura-del-proyecto)
6. [Ejecución](#ejecución)
7. [Testing](#testing)
8. [Modelo de IA](#modelo-de-ia)
9. [Módulo C++ FFI](#módulo-c-ffi)
10. [Seguridad SDLC](#seguridad-sdlc)
11. [Métricas MIR](#métricas-mir)
12. [Formatos de Exportación](#formatos-de-exportación)

---

## Descripción

PianoScribe convierte interpretaciones de **piano electrónico** (archivos MP3/WAV) en partituras musicales estructuradas mediante:

- **Modelo Onsets and Frames** (inspirado en Magenta de Google) ejecutado con **TensorFlow Lite** de forma completamente **offline**
- **Preprocesamiento DSP** de alto rendimiento en **C++ via Dart FFI** (espectrograma Mel)
- **Exportación** a formatos **MIDI** y **MusicXML** (pentagrama con clave de sol)
- **Almacenamiento local** en **SQLite** con cifrado AES-256-CBC
- **Evaluación MIR** con objetivos de F-measure ≥75% (monofónico) y ≥60% (polifónico)

> ⚠️ **Solo piano**: El sistema NO soporta transcripción de voces humanas ni otros instrumentos.

---

## Arquitectura

El proyecto implementa **Clean Architecture** con patrón **BLoC**:

```
┌─────────────────────────────────────────────────┐
│                  Presentation                    │
│   ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│   │  Pages   │  │  Widgets │  │    BLoCs      │ │
│   └──────────┘  └──────────┘  └──────────────┘ │
├─────────────────────────────────────────────────┤
│                    Domain                        │
│   ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│   │ Entities │  │ UseCases │  │ Repositories* │ │
│   └──────────┘  └──────────┘  └──────────────┘ │
├─────────────────────────────────────────────────┤
│                     Data                         │
│   ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│   │  Models  │  │   Repos  │  │ DataSources   │ │
│   │          │  │  (impl)  │  │ (SQLite/FFI)  │ │
│   └──────────┘  └──────────┘  └──────────────┘ │
├─────────────────────────────────────────────────┤
│                     Core                         │
│   ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│   │Constants │  │Security  │  │    Utils      │ │
│   │  Errors  │  │Validator │  │ MIDI/MIR/XML  │ │
│   └──────────┘  └──────────┘  └──────────────┘ │
└─────────────────────────────────────────────────┘
  * = abstract contracts
```

---

## Requisitos Previos

### Software necesario

| Herramienta | Versión mínima | Descarga |
|-------------|----------------|----------|
| **Flutter SDK** | 3.11+ | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.11+ | Incluido con Flutter |
| **Android Studio** | 2024+ | [developer.android.com/studio](https://developer.android.com/studio) |
| **VS Code** | Latest | [code.visualstudio.com](https://code.visualstudio.com) |
| **Git** | Any | [git-scm.com](https://git-scm.com/downloads) |
| **JDK** | 17+ | Incluido en Android Studio |

### Extensiones de VS Code (requeridas)

1. **Dart** – `Dart-Code.dart-code`
2. **Flutter** – `Dart-Code.flutter`
3. **Flutter BLoC** – `FelixAngelov.bloc`

```bash
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
code --install-extension FelixAngelov.bloc
```

### Android SDK

Asegúrate de tener instalados:
- Android SDK Platform 33+
- Android SDK Build-Tools 33+
- Android Emulator (para testing)

---

## Instalación Paso a Paso

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/<tu-usuario>/yanita_music.git
cd yanita_music
```

### Paso 2: Verificar Flutter

```bash
flutter doctor -v
```

Asegúrate de que no haya errores críticos (✓ en Flutter, Android toolchain, VS Code).

### Paso 3: Instalar dependencias

```bash
cd src/yanita_music
flutter pub get
```

### Paso 4: Verificar análisis estático

```bash
flutter analyze
```

### Paso 5: Crear directorio de assets

```bash
mkdir -p assets/models
```

Coloca el modelo TFLite (`onsets_and_frames.tflite`) en `assets/models/`.

> **Nota**: El modelo debe ser convertido del formato SavedModel de Magenta a TFLite.
> Ver sección [Modelo de IA](#modelo-de-ia).

### Paso 6: Ejecutar en emulador o dispositivo

```bash
flutter run
```

---

## Estructura del Proyecto

```
src/yanita_music/
├── lib/
│   ├── main.dart                          # Entry point con DI
│   ├── injection_container.dart           # Service Locator (get_it)
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart         # Configuración global
│   │   │   ├── audio_constants.dart       # Parámetros DSP
│   │   │   └── db_constants.dart          # Nombres de tablas/columnas
│   │   ├── error/
│   │   │   ├── exceptions.dart            # Excepciones de capa data
│   │   │   └── failures.dart              # Failures de capa domain
│   │   ├── security/
│   │   │   ├── file_validator.dart         # Validación de archivos (sync I/O)
│   │   │   ├── encryption_service.dart     # AES-256-CBC
│   │   │   └── secure_storage_service.dart # Keystore nativo
│   │   ├── usecases/
│   │   │   └── usecase.dart               # Contrato base UseCase
│   │   └── utils/
│   │       ├── audio_decoder.dart         # Decodificador WAV/MP3
│   │       ├── input_sanitizer.dart       # Prevención SQL injection
│   │       ├── logger.dart                # Logger centralizado
│   │       ├── midi_utils.dart            # Generador MIDI (legacy)
│   │       ├── midi_writer.dart           # Escritor MIDI estándar
│   │       ├── mir_evaluator.dart         # Métricas MIR
│   │       └── music_xml_generator.dart   # Generador MusicXML
│   │
│   ├── domain/
│   │   ├── entities/                      # Objetos de negocio puros
│   │   │   ├── audio_features.dart
│   │   │   ├── midi_event.dart
│   │   │   ├── note_event.dart
│   │   │   ├── score.dart
│   │   │   └── song.dart
│   │   ├── repositories/                  # Contratos abstractos
│   │   │   ├── audio_repository.dart
│   │   │   ├── score_repository.dart
│   │   │   ├── songbook_repository.dart
│   │   │   └── transcription_repository.dart
│   │   └── usecases/                      # Casos de uso SRP
│   │       ├── add_song_usecase.dart
│   │       ├── delete_score_usecase.dart
│   │       ├── evaluate_metrics_usecase.dart
│   │       ├── export_midi_usecase.dart
│   │       ├── export_musicxml_usecase.dart
│   │       ├── get_scores_usecase.dart
│   │       ├── get_songs_usecase.dart
│   │       ├── process_audio_usecase.dart
│   │       ├── save_score_usecase.dart
│   │       └── transcribe_audio_usecase.dart
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   ├── database_helper.dart        # SQLite singleton
│   │   │   │   ├── score_local_datasource.dart  # CRUD partituras
│   │   │   │   └── songbook_local_datasource.dart
│   │   │   └── native/
│   │   │       └── audio_processor_ffi.dart     # Bridge C++ FFI
│   │   ├── models/                              # DTOs con serialización
│   │   │   ├── audio_features_model.dart
│   │   │   ├── note_event_model.dart
│   │   │   ├── score_model.dart
│   │   │   └── song_model.dart
│   │   └── repositories/                        # Implementaciones concretas
│   │       ├── audio_repository_impl.dart
│   │       ├── score_repository_impl.dart
│   │       ├── songbook_repository_impl.dart
│   │       └── transcription_repository_impl.dart
│   │
│   └── presentation/
│       ├── blocs/
│       │   ├── transcription/           # BLoC principal AMT
│       │   │   ├── transcription_bloc.dart
│       │   │   ├── transcription_event.dart
│       │   │   └── transcription_state.dart
│       │   ├── score_library/           # BLoC biblioteca
│       │   │   ├── score_library_bloc.dart
│       │   │   ├── score_library_event.dart
│       │   │   └── score_library_state.dart
│       │   └── songbook/                # BLoC cancionero
│       │       ├── songbook_bloc.dart
│       │       ├── songbook_event.dart
│       │       └── songbook_state.dart
│       ├── pages/
│       │   ├── home_page.dart            # Navegación principal
│       │   ├── transcription_page.dart   # Upload + transcripción
│       │   ├── score_library_page.dart   # Partituras guardadas
│       │   ├── songbook_page.dart        # Cancionero usuario
│       │   └── score_detail_page.dart    # Detalle + piano roll
│       └── theme/
│           └── app_theme.dart            # Material 3 dark theme
│
├── test/
│   ├── core/utils/
│   │   └── input_sanitizer_test.dart
│   ├── data/models/
│   │   └── note_event_model_test.dart
│   └── domain/usecases/
│       └── evaluate_metrics_usecase_test.dart
│
├── assets/
│   └── models/                           # Modelo TFLite (no incluido)
│
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Ejecución

### En emulador Android

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device-id>
```

### Hot reload

Presiona `r` en la terminal o `Ctrl+S` en VS Code para hot reload.

---

## Testing

```bash
# Ejecutar todos los tests
flutter test

# Test específico
flutter test test/core/utils/input_sanitizer_test.dart

# Con coverage
flutter test --coverage
```

---

## Modelo de IA

### Onsets and Frames (TFLite)

El modelo está basado en el paper de Google Magenta "Onsets and Frames" para transcripción automática de piano:

- **Input**: Espectrograma Mel `[1, frames, 229, 1]`
- **Output Onsets**: `[1, frames, 88]` – probabilidad de comienzo de nota
- **Output Frames**: `[1, frames, 88]` – probabilidad de nota activa
- **Output Velocity**: `[1, frames, 88]` – velocidad estimada

### Conversión a TFLite

```python
# Usar tf-nightly o tensorflow 2.x
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model('path/to/saved_model')
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS,
]
tflite_model = converter.convert()

with open('assets/models/onsets_and_frames.tflite', 'wb') as f:
    f.write(tflite_model)
```

---

## Módulo C++ FFI

El procesamiento DSP se realiza en C++ nativo para máximo rendimiento:

```
Archivo MP3 → minimp3 (decode) → Resample 16kHz mono → FFT (KissFFT) → Mel Spectrogram
```

La librería compartida se compila como:
- **Android**: `libaudio_processor.so` (arm64-v8a, armeabi-v7a)
- **iOS**: Framework estático

---

## Seguridad SDLC

| Medida | Implementación |
|--------|----------------|
| SQL Injection | Queries parametrizadas en SQLite + `InputSanitizer` |
| Validación de archivos | `FileValidator` con extensión, tamaño y checksum SHA-256 |
| Cifrado en reposo | AES-256-CBC con IV aleatorio (`EncryptionService`) |
| Almacenamiento de claves | Android Keystore / iOS Keychain (`SecureStorageService`) |
| Análisis estático | `analysis_options.yaml` con reglas estrictas incluyendo `avoid_slow_async_io` |
| XSS Prevention | `InputSanitizer.sanitizeText()` remueve caracteres peligrosos |

---

## Métricas MIR

El sistema evalúa su desempeño comparando transcripciones contra ground truth:

| Métrica | Objetivo | Descripción |
|---------|----------|-------------|
| Precision | ≥75% mono | Notas correctas / Total predichas |
| Recall | ≥75% mono | Notas correctas / Total reales |
| F-measure | ≥75% mono, ≥60% poli | Media armónica de P y R |

Tolerancia de onset: **50ms** (configurable en `AppConstants`).

---

## Formatos de Exportación

### MIDI (Format 0)
- Compatible con cualquier DAW o software de notación
- Incluye eventos Note On/Off con velocidad
- Tempo configurable

### MusicXML 4.0
- Compatible con MuseScore, Finale, Sibelius
- Pentagrama con clave de Sol
- Incluye dinámicas y tempo

---

## Dependencias Principales

| Paquete | Uso |
|---------|-----|
| `flutter_bloc` | State management (patrón BLoC) |
| `get_it` | Dependency injection |
| `sqflite` | Base de datos SQLite |
| `tflite_flutter` | Inferencia TensorFlow Lite |
| `dartz` | Programación funcional (`Either`) |
| `equatable` | Comparación de objetos |
| `crypto` | SHA-256 checksums |
| `pointycastle` | Cifrado AES-256-CBC |
| `flutter_secure_storage` | Keystore nativo |
| `file_picker` | Selección de archivos |
| `share_plus` | Compartir exportaciones |
| `google_fonts` | Tipografía premium |

---

## Licencia

Este proyecto es para uso académico (Maestría). Todos los derechos reservados.

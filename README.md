
# YANITA MUSIC MVP 

## Descripción
Aplicación móvil desarrollada como MVP que permite realizar transcripción musical automática de interpretaciones de piano electrónico a partir de archivos de audio MP3.
El sistema utiliza técnicas de Automatic Music Transcription (AMT) basadas en modelos de inteligencia artificial ejecutados localmente mediante TensorFlow Lite, permitiendo convertir interpretaciones musicales en representaciones estructuradas como MIDI y MusicXML, las cuales posteriormente pueden visualizarse como partituras en pentagrama con clave de sol.

El procesamiento del audio se realiza completamente offline, integrando un módulo de análisis de señales musicales de alto rendimiento desarrollado en C++ mediante Dart FFI, encargado de generar espectrogramas que sirven como entrada para el modelo de inteligencia artificial.

## Objetivo general
Desarrollar un MVP de aplicación móvil capaz de transcribir automáticamente interpretaciones de piano desde archivos MP3 hacia partituras musicales estructuradas utilizando inteligencia artificial y procesamiento de audio offline.

## Objetivos específicos (medibles)
- Implementar un módulo de preprocesamiento de audio en C++ capaz de generar espectrogramas Mel desde archivos MP3.
- Integrar un modelo de transcripción musical basado en aprendizaje profundo ejecutado con TensorFlow Lite.
- Convertir las predicciones del modelo en eventos musicales estructurados (MIDI y MusicXML).
- Implementar almacenamiento local mediante SQLite para gestionar el cancionero del usuario y las partituras generadas.
- Desarrollar una interfaz móvil en Flutter utilizando Clean Architecture y patrón BLoC.
- Evaluar el sistema mediante métricas de Music Information Retrieval, buscando alcanzar F-measure > 75% en señales monofónicas y > 60% en señales polifónicas de piano.

## Alcance (qué incluye / qué NO incluye)
Incluye:
- Carga de archivos MP3 para transcripción
- Procesamiento de audio local mediante C++ + Dart FFI
- Transcripción musical automática usando modelo de IA ejecutado en TensorFlow Lite
- Generación de archivos MIDI y MusicXML
- Generación de partitura musical en pentagrama
- Almacenamiento local de canciones y partituras con SQLite
- Arquitectura basada en Clean Architecture y patrón BLoC
- Funcionamiento completamente offline

No incluye (por ahora):
- Transcripción en tiempo real desde micrófono
- Soporte para otros instrumentos musicales
- Sincronización con servicios en la nube
- Edición avanzada de partituras
- Funciones sociales o colaboración entre usuarios

## Stack tecnológico
Frontend móvil
- Flutter
- Dart
- BLoC (gestión de estado)

Procesamiento de audio
- C++
- Dart FFI
- FFT
- Mel Spectrogram

Inteligencia artificial
- TensorFlow Lite
- Modelos de transcripción musical inspirados en Magenta (Onsets and Frames / MT3)

Base de datos
- SQLite

Testing
- Pruebas funcionales locales
- Evaluación con métricas MIR

Control de versiones
- Git
- GitHub / GitLab

## Arquitectura (resumen)
El sistema sigue el patrón Clean Architecture separando responsabilidades en capas:

presentation
- UI Flutter
- BLoC

domain
- entidades
- casos de uso

data
- repositorios
- datasource SQLite
- datasource TensorFlow Lite

core
- utilidades
- seguridad

Flujo del sistema:

MP3
→ Preprocesamiento de audio (C++)
→ Mel Spectrogram
→ TensorFlow Lite (modelo AMT)
→ Eventos musicales
→ MIDI / MusicXML
→ Partitura musical

## Endpoints core (priorizados)
El sistema funciona completamente offline, por lo que los casos de uso principales son:

1. Cargar archivo MP3 para transcripción
2. Procesar audio y generar espectrograma
3. Ejecutar modelo de IA para detectar notas musicales
4. Generar archivo MIDI
5. Convertir MIDI a MusicXML
6. Guardar partitura generada en SQLite

## Cómo ejecutar el proyecto (local)

1. Clonar repositorio
git clone <URL_DEL_REPOSITORIO>

2. Entrar al proyecto
cd piano_amt_app

3. Instalar dependencias
flutter pub get

4. Colocar el modelo de IA
assets/model/model.tflite

5. Ejecutar la aplicación
flutter run

## Variables de entorno (ejemplo)

APP_ENV=development
MODEL_PATH=assets/model/model.tflite
DATABASE_NAME=songs.db

## Equipo y roles
- Gustavo: Arquitectura de software / IA / Backend
- Desarrollador Flutter: Frontend móvil
- QA / Testing: Validación funcional y evaluación MIR
- DevOps: Automatización de builds y control de versiones

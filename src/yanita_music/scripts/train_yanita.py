import os
import tensorflow as tf
import numpy as np
import librosa
import xml.etree.ElementTree as ET
import logging
from datetime import datetime

# --- CONFIGURACIÓN DE LOGS ---
log_filename = f"training_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.FileHandler(log_filename),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("YanitaTrain")

# --- CONFIGURACIÓN DE MEMORIA Y CONTROL ---
# Estos parámetros controlan la utilización de recursos.
BATCH_SIZE = 4  # Ajustar según VRAM disponible
SAMPLE_RATE = 16000
WINDOW_SECONDS = 2.0  # Tamaño del fragmento de audio 
EPOCHS = 50
LEARNING_RATE = 0.0001

TRAINING_DATA_DIR = '../assets/training_data'

def load_data_generator():
    """
    GENERADOR DE DATOS (Lazy Loading): 
    Esta función es CLAVE para la gestión de memoria. 
    Solo carga los archivos necesarios para el lote actual.
    """
    pieces = [f.split('.')[0] for f in os.listdir(TRAINING_DATA_DIR) if f.endswith('.mxl')]
    
    for piece in pieces:
        logger.info(f"Cargando datos para pieza: {piece}")
        audio_path = os.path.join(TRAINING_DATA_DIR, f"{piece}.mp3")
        
        if not os.path.exists(audio_path):
            logger.error(f"Archivo de audio no encontrado: {audio_path}")
            continue

        # Cargar audio solo cuando se necesite
        y_raw, _ = librosa.load(audio_path, sr=SAMPLE_RATE)
        y: np.ndarray = np.array(y_raw)
        
        # Simulación de extracción de etiquetas (Labels) desde MusicXML
        # En un piano roll real, las muestras de tiempo deben coincidir con los frames de FFT.
        hop_length = 160
        num_total_frames = len(y) // hop_length
        labels: np.ndarray = np.zeros((num_total_frames + 1, 88))
        
        # Generar fragmentos para no saturar la RAM
        for start_sample in range(0, len(y) - int(SAMPLE_RATE * WINDOW_SECONDS), int(SAMPLE_RATE * WINDOW_SECONDS)):
            end_sample = start_sample + int(SAMPLE_RATE * WINDOW_SECONDS)
            audio_chunk = y[start_sample:end_sample]
            
            # Transformación Mel (Simulando lo que hace el C++)
            # n_mels=229 para coincidir con el procesador nativo
            mel_spec_raw = librosa.feature.melspectrogram(y=audio_chunk, sr=SAMPLE_RATE, n_mels=229, hop_length=hop_length)
            mel_spec: np.ndarray = np.array(mel_spec_raw)
            n_frames = mel_spec.shape[1]
            
            # Asegurar que no excedemos el tamaño de etiquetas
            labels_chunk = labels[:n_frames, :]
            yield mel_spec.T, labels_chunk

def create_model():
    """
    Arquitectura compatible con TFLite.
    """
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(None, 229)),
        tf.keras.layers.Conv1D(64, 3, activation='relu', padding='same'),
        tf.keras.layers.LSTM(128, return_sequences=True),
        tf.keras.layers.Dense(88, activation='sigmoid') # 88 notas salida
    ])
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    return model

if __name__ == "__main__":
    logger.info("--- Iniciando Pipeline de Entrenamiento para Yanita Music ---")
    
    if not os.path.exists(TRAINING_DATA_DIR):
        logger.error(f"Directorio de datos de entrenamiento no encontrado: {TRAINING_DATA_DIR}")
        exit(1)

    # 1. Crear Dataset usando el Generador para GESTIÓN DE MEMORIA
    dataset = tf.data.Dataset.from_generator(
        load_data_generator,
        output_signature=(
            tf.TensorSpec(shape=(None, 229), dtype=tf.float32),
            tf.TensorSpec(shape=(None, 88), dtype=tf.float32)
        )
    ).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

    # 2. Crear y controlar el entrenamiento
    logger.info("Compilando modelo compatible con TFLite...")
    model = create_model()
    
    # Callbacks para CONTROL
    if not os.path.exists('checkpoints'):
        os.makedirs('checkpoints')
        logger.info("Directorio 'checkpoints' creado.")

    callbacks = [
        tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
        tf.keras.callbacks.ModelCheckpoint('checkpoints/yanita_weights.h5', save_best_only=True)
    ]

    logger.info(f"Entrenando por {EPOCHS} épocas con gestión de memoria activa...")
    # model.fit(dataset, epochs=EPOCHS, callbacks=callbacks)
    
    logger.info("Simulación completa: Script listo para ejecución en entorno Python.")

import os
import librosa
import numpy as np
import music21
import tensorflow as tf
from music21 import converter, note, chord

# Configuración
DATA_DIR = "assets/training_data"
SAMPLE_RATE = 16000
HOP_LENGTH = 512
N_MELS = 229

def load_musicxml(xml_path):
    """Carga la partitura y extrae los eventos de notas (tiempo, pitch)."""
    score = converter.parse(xml_path)
    notes = []
    for element in score.flat.notes:
        start = float(element.offset)
        duration = float(element.quarterLength)
        if isinstance(element, note.Note):
            notes.append((start, start + duration, element.pitch.midi))
        elif isinstance(element, chord.Chord):
            for n in element.notes:
                notes.append((start, start + duration, n.pitch.midi))
    return sorted(notes)

def audio_to_mel(audio_path):
    """Convierte audio a espectrograma Mel (similar al audio_processor.cpp)."""
    y, sr = librosa.load(audio_path, sr=SAMPLE_RATE)
    mel = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=N_MELS, hop_length=HOP_LENGTH)
    return librosa.power_to_db(mel, ref=np.max).T

def create_labels(notes, num_frames, duration_seconds):
    """Crea una matriz de etiquetas (piano roll) para el entrenamiento."""
    labels = np.zeros((num_frames, 88)) # 88 teclas de piano (MIDI 21-108)
    frame_duration = duration_seconds / num_frames
    
    for start, end, pitch in notes:
        if 21 <= pitch <= 108:
            start_frame = int(start / frame_duration)
            end_frame = int(end / frame_duration)
            labels[start_frame:end_frame, pitch - 21] = 1
    return labels

def prepare_dataset():
    """Busca pares MusicXML/MP3 y prepara los datos."""
    X, Y = [], []
    files = os.listdir(DATA_DIR)
    xml_files = [f for f in files if f.endswith(".mxl")]
    
    for xml_file in xml_files:
        base_name = xml_file.replace(".mxl", "")
        mp3_file = base_name + ".mp3"
        mp3_path = os.path.join(DATA_DIR, mp3_file)
        
        if os.path.exists(mp3_path):
            print(f"Procesando: {base_name}...")
            try:
                # Cargar datos
                notes = load_musicxml(os.path.join(DATA_DIR, xml_file))
                mel = audio_to_mel(mp3_path)
                
                # Alinear etiquetas
                duration = librosa.get_duration(path=mp3_path)
                labels = create_labels(notes, mel.shape[0], duration)
                
                X.append(mel)
                Y.append(labels)
            except Exception as e:
                print(f"Error procesando {base_name}: {e}")
                
    return np.array(X), np.array(Y)

if __name__ == "__main__":
    print("Iniciando preparación de datos de entrenamiento...")
    # Instrucciones:
    # 1. Instalar dependencias: pip install librosa music21 tensorflow numpy
    # 2. Asegurarse de que los archivos MP3 y MXL tengan el mismo nombre base en assets/training_data/
    
    # X, Y = prepare_dataset()
    # print(f"Dataset listo: {len(X)} muestras encontradas.")
    
    # Aquí se procedería con tf.keras.Model.fit(...)
    print("Nota: Este script es una base. El entrenamiento real requiere GPUs y miles de archivos.")
    print("Usa este script para validar tus pares de datos locales.")

-- Eliminar si ya existe para ejecución limpia
DROP TABLE IF EXISTS scoresTable;
DROP TABLE IF EXISTS songsTable;

-- Tabla de Partituras
CREATE TABLE scoresTable (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT NOT NULL,
  audioPath TEXT NOT NULL,
  noteEvents TEXT NOT NULL DEFAULT '[]',
  midiData TEXT,
  createdAt TEXT NOT NULL
);

-- Tabla del Cancionero
CREATE TABLE songsTable (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT NOT NULL,
  artist TEXT,
  audioPath TEXT NOT NULL,
  scorePath TEXT,
  coverPath TEXT,
  isDemo INTEGER DEFAULT 0,
  difficulty TEXT,
  duration INTEGER,
  createdAt TEXT NOT NULL
);

-- Poblar canciones Demo (las primeras 3)
INSERT INTO songsTable (id, title, artist, audioPath, scorePath, coverPath, isDemo, difficulty, duration, createdAt) VALUES
('d1a1f3c0-xxxx', 'Bach: Minuet in G', 'J.S. Bach', 'assets/audio/bach_minuet_g.mp3', 'assets/scores/bach_minuet_g.mxl', 'assets/images/placeholder.jpg', 1, 'Fácil', 132, 'str-date'),
('d1a1f3c1-xxxx', 'Beethoven: 5th Symphony', 'L. van Beethoven', 'assets/audio/beethoven_5th_symphony.mp3', 'assets/scores/beethoven_5th_symphony.mxl', 'assets/images/placeholder.jpg', 1, 'Avanzado', 120, 'str-date'),
('d1a1f3c2-xxxx', 'Bella Ciao', 'Traditional', 'assets/audio/bella_ciao.mp3', 'assets/scores/bella_ciao.mxl', 'assets/images/placeholder.jpg', 1, 'Intermedio', 120, 'str-date');

-- Poblar Partituras (igual que hace DatabaseHelper ahora para mostrar en Inicio)
INSERT INTO scoresTable (id, title, audioPath, noteEvents, midiData, createdAt) VALUES
('d1a1f3c0-xxxx', 'Bach: Minuet in G', 'assets/audio/bach_minuet_g.mp3', '[]', NULL, 'str-date'),
('d1a1f3c1-xxxx', 'Beethoven: 5th Symphony', 'assets/audio/beethoven_5th_symphony.mp3', '[]', NULL, 'str-date'),
('d1a1f3c2-xxxx', 'Bella Ciao', 'assets/audio/bella_ciao.mp3', '[]', NULL, 'str-date');

-- Ajustes de Visualización
.mode markdown
.headers on

-- VALIDACIÓN: SELECT QUERY
SELECT '>>> VERIFICANDO CANCIONES DEMO (songsTable) <<<' as Accion;
SELECT id, title, artist, audioPath, isDemo FROM songsTable WHERE isDemo = 1 LIMIT 3;

SELECT '>>> VERIFICANDO PARTITURAS INICIO (scoresTable) <<<' as Accion;
SELECT id, title, audioPath, noteEvents FROM scoresTable LIMIT 3;

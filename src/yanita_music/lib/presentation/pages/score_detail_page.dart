import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/presentation/widgets/score_stave_visualizer.dart';

/// Página de detalle de una partitura transcrita con controles de reproducción.
class ScoreDetailPage extends StatefulWidget {
  final Score score;

  const ScoreDetailPage({super.key, required this.score});

  @override
  State<ScoreDetailPage> createState() => _ScoreDetailPageState();
}

class _ScoreDetailPageState extends State<ScoreDetailPage> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late Ticker _ticker;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _showNoteNames = true;
  double _currentTime = 0.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
    
    // Ticker para actualización suave del pentagrama (60fps)
    _ticker = createTicker((elapsed) {
      if (_isPlaying) {
        final position = _audioPlayer.position.inMilliseconds / 1000.0;
        if (mounted && position != _currentTime) {
          setState(() {
            _currentTime = position;
          });
        }
      }
    });
  }

  Future<void> _initAudio() async {
    if (widget.score.audioPath.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (widget.score.audioPath.startsWith('http')) {
        await _audioPlayer.setUrl(widget.score.audioPath);
      } else if (widget.score.audioPath.startsWith('assets/')) {
        await _audioPlayer.setAsset(widget.score.audioPath);
      } else {
        await _audioPlayer.setFilePath(widget.score.audioPath);
      }

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (_isPlaying) {
              _ticker.start();
            } else {
              _ticker.stop();
            }
            
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _ticker.stop();
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
              setState(() => _currentTime = 0.0);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error inicializando audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.score.title, style: GoogleFonts.inter(fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(
              _showNoteNames ? Icons.label : Icons.label_off_outlined,
              color: _showNoteNames ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: 'Mostrar nombres de notas',
            onPressed: () => setState(() => _showNoteNames = !_showNoteNames),
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visualización de Notas (Pentagrama)
            ScoreStaveVisualizer(
              score: widget.score,
              currentTime: _currentTime,
              isPlaying: _isPlaying,
              showNoteNames: _showNoteNames,
            ),
            const SizedBox(height: 24),

            // Controles de Reproducción
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _isLoading
                            ? const SizedBox(
                                width: 48,
                                height: 48,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: _togglePlayback,
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  activeTrackColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  inactiveTrackColor: Colors.white10,
                                ),
                                child: Slider(
                                  value: (_currentTime / widget.score.duration)
                                      .clamp(0.0, 1.0),
                                  onChanged: (value) {
                                    final position = Duration(
                                      milliseconds:
                                          (value * widget.score.duration * 1000)
                                              .toInt(),
                                    );
                                    _audioPlayer.seek(position);
                                    setState(() {
                                      _currentTime = value * widget.score.duration;
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatTime(_currentTime),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(widget.score.duration),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Información general con iconos para mayor "uniformidad"
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Detalles de la Transcripción',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      context,
                      Icons.music_note,
                      'Notas detectadas',
                      '${widget.score.noteCount}',
                    ),
                    _buildDetailRow(
                      context,
                      Icons.speed,
                      'Tempo',
                      widget.score.tempo != null
                          ? '${widget.score.tempo!.toStringAsFixed(0)} BPM'
                          : 'No detectado',
                    ),
                    _buildDetailRow(
                      context,
                      Icons.layers,
                      'Tipo',
                      widget.score.isPolyphonic ? 'Polifónica' : 'Monofónica',
                    ),
                    _buildDetailRow(
                      context,
                      Icons.calendar_today,
                      'Fecha',
                      _formatDate(widget.score.createdAt),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

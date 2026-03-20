import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/presentation/blocs/score_library/score_library_bloc.dart';
import 'package:yanita_music/presentation/blocs/transcription/transcription_bloc.dart';
import 'package:yanita_music/presentation/pages/transcription_page.dart';
import 'package:yanita_music/presentation/pages/score_library_page.dart';
import 'package:yanita_music/presentation/pages/songbook_page.dart';
import 'package:yanita_music/presentation/pages/login_page.dart';
import 'package:yanita_music/presentation/widgets/score_stave_visualizer.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yanita_music/core/constants/version_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _DashboardView(),
    const TranscriptionPage(),
    const ScoreLibraryPage(),
    const SongbookPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: const Color(0xFFFF9800), // Naranja 500
        unselectedItemColor: const Color(0xFF666666), // Gris neutro
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.piano),
            label: 'Transcribir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Cancionero'),
        ],
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with SingleTickerProviderStateMixin {
  Score? _selectedScore;
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  late AnimationController _playbackController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _playbackController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            setState(() {});
          });

    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((position) {
      if (_selectedScore != null && _selectedScore!.duration > 0) {
        final double progress =
            position.inMilliseconds / (_selectedScore!.duration * 1000);
        // Sincronización directa y forzada
        if (mounted) {
          _playbackController.value = progress.clamp(0.0, 1.0);
        }
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _playbackController.stop();
          _playbackController.value = 1.0;
        });
      }
    });

    // Cargar partituras al iniciar
    context.read<ScoreLibraryBloc>().add(LoadScores());
  }

  @override
  void dispose() {
    _playbackController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadScore(Score score) async {
    _stopPlayback();
    setState(() {
      _selectedScore = score;
      _isAudioLoading = true;
    });

    try {
      if (score.audioPath.isNotEmpty) {
        if (score.audioPath.startsWith('http')) {
          await _audioPlayer.setUrl(score.audioPath);
        } else if (score.audioPath.startsWith('assets/')) {
          await _audioPlayer.setAsset(score.audioPath);
        } else {
          await _audioPlayer.setFilePath(score.audioPath);
        }
      }

      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _playbackController.duration = Duration(
            milliseconds: (score.duration * 1000).toInt(),
          );
          _isPlaying = true;
        });

        // Auto-reproducir la partitura al cargar en inicio
        // Nota: NO llamamos a _playbackController.forward()
        // El progreso lo dicta el positionStream del reproductor.
        _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando audio: $e')));
      }
    }
  }

  void _togglePlayback() {
    if (_selectedScore == null || _isAudioLoading) return;
    setState(() {
      if (_isPlaying) {
        _audioPlayer.pause();
        _playbackController.stop();
      } else {
        if (_playbackController.isCompleted) {
          _playbackController.reset();
          _audioPlayer.seek(Duration.zero);
        }
        _audioPlayer.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _stopPlayback() {
    setState(() {
      _isPlaying = false;
      _audioPlayer.stop();
      _audioPlayer.seek(Duration.zero);
      _playbackController.reset();
      _playbackController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TranscriptionBloc, TranscriptionState>(
      listener: (context, state) {
        if (state is TranscriptionSaved) {
          context.read<ScoreLibraryBloc>().add(LoadScores());
          _stopPlayback();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFF8F9FA),
          ),
          title: Column(
            children: [
              Text(
                'REPRODUCIENDO PARTITURA',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: const Color(0xFFCCCCCC),
                ),
              ),
              Text(
                _selectedScore?.title ?? 'Selecciona una partitura',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Color(0xFFFF9800)),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              tooltip: 'Cerrar Sesión',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Área Principal: Partitura o Logo
                Center(
                  child: _selectedScore != null
                      ? ScoreStaveVisualizer(
                          score: _selectedScore!,
                          currentTime:
                              _playbackController.value *
                              (_selectedScore?.duration ?? 1.0),
                          isPlaying: _isPlaying,
                        )
                      : Container(
                          height: 320,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/logo.png'),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 32),

                // Información de la Partitura Seleccionada
                if (_selectedScore != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedScore!.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Piano - Transcripción Automática',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.favorite_border,
                        color: Color(0xFFFF9800),
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Barra de Progreso
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: const Color(0xFFFF9800),
                          inactiveTrackColor: Colors.white10,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _playbackController.value,
                          onChanged: (value) {
                            setState(() {
                              _playbackController.value = value;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(
                                _playbackController.value *
                                    (_selectedScore?.duration ?? 0),
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatTime(_selectedScore?.duration ?? 0),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Controles de Reproducción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.stop,
                          color: Color(0xFFE65100),
                          size: 32,
                        ),
                        onPressed: _stopPlayback,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 42,
                        ),
                        onPressed: () => _playbackController.reset(),
                      ),
                      GestureDetector(
                        onTap: _togglePlayback,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: _isAudioLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF121212),
                                    strokeWidth: 3,
                                  ),
                                )
                              : Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: const Color(0xFF121212),
                                  size: 40,
                                ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 42,
                        ),
                        onPressed: () => _playbackController.forward(from: 1.0),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.repeat,
                          color: Color(0xFFFF9800),
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ] else ...[
                  // Mensaje si no hay nada seleccionado
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Carga una partitura desde tus últimas transcripciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                // Sección de Últimas Partituras
                Text(
                  'Tus Últimas Partituras',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                BlocBuilder<ScoreLibraryBloc, ScoreLibraryState>(
                  builder: (context, state) {
                    if (state is ScoreLibraryLoaded) {
                      final recentScores = state.scores.take(3).toList();
                      if (recentScores.isEmpty) {
                        return const Text(
                          'Aún no tienes partituras. ¡Ve a Transcribir!',
                        );
                      }
                      return Column(
                        children: recentScores
                            .map((score) => _buildScoreItem(score))
                            .toList(),
                      );
                    } else if (state is ScoreLibraryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      return const Text(
                        'No se encontraron partituras recientes.',
                      );
                    }
                  },
                ),
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Yanita Music',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Versión ${VersionConstants.fullVersion}',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '© 2026 Yanita Music Team',
                        style: TextStyle(color: Colors.white10, fontSize: 8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(Score score) {
    final bool isSelected = _selectedScore?.id == score.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.piano, color: Color(0xFFFF9800)),
        ),
        title: Text(
          score.title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF9800) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: const Text(
          'Piano - Transcripción Automática',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: isSelected && _isPlaying
            ? const Icon(Icons.graphic_eq, color: Color(0xFFFF9800))
            : const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () => _loadScore(score),
      ),
    );
  }

  String _formatTime(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

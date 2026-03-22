import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:yanita_music/presentation/pages/login_page.dart';
import '../../core/constants/version_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _loadingProgress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Iniciar el temporizador para la barra de carga (10% cada 1.5s = 15s total)
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        if (_loadingProgress < 1.0) {
          _loadingProgress += 0.1;
          if (_loadingProgress > 1.0) _loadingProgress = 1.0;
        } else {
          _timer?.cancel();
          _navigateToLogin();
        }
      });
    });
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Fondo de estrellas
          Positioned.fill(
            child: CustomPaint(painter: StarPainter(_controller)),
          ),
          // Contenido Principal
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.music_note_rounded,
                        size: 150,
                        color: Color(0xFFFF9800), // Naranja 500
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Yanita Music',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8F9FA),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Barra de Carga
                  Column(
                    children: [
                      Container(
                        width: 250,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 250 * _loadingProgress,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF9800,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cargando... ${(_loadingProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Versión en la parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: FadeTransition(
              opacity: _animation,
              child: const Center(
                child: Text(
                  'v${VersionConstants.fullVersion}',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Offset> stars = List.generate(
    100,
    (index) => Offset(Random().nextDouble(), Random().nextDouble()),
  );

  StarPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      final x = star.dx * size.width;
      final y = star.dy * size.height;
      // Brillo aleatorio basado en la animación
      final opacity =
          (sin(animation.value * 2 * pi * (stars.indexOf(star) % 5 + 1)) + 1) /
          2;
      paint.color = Colors.white.withValues(alpha: opacity * 0.8);
      canvas.drawCircle(Offset(x, y), Random().nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

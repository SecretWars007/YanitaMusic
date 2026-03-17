import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yanita_music/presentation/blocs/score_library/score_library_bloc.dart';
import 'package:yanita_music/presentation/blocs/songbook/songbook_bloc.dart';
import 'package:yanita_music/presentation/pages/transcription_page.dart';
import 'package:yanita_music/presentation/pages/score_library_page.dart';
import 'package:yanita_music/presentation/pages/songbook_page.dart';

/// Pantalla principal con navegación inferior de 3 tabs.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = const [
    TranscriptionPage(),
    ScoreLibraryPage(),
    SongbookPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Precargar datos de biblioteca y cancionero
    context.read<ScoreLibraryBloc>().add(LoadScores());
    context.read<SongbookBloc>().add(LoadSongs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            activeIcon: Icon(Icons.music_note, size: 28),
            label: 'Transcribir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            activeIcon: Icon(Icons.library_music, size: 28),
            label: 'Partituras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            activeIcon: Icon(Icons.book, size: 28),
            label: 'Cancionero',
          ),
        ],
      ),
    );
  }
}

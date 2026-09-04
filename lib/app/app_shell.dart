import 'package:flutter/material.dart';
import '../features/creator/creator_page.dart';
import '../features/hall/hall_page.dart';
import '../features/library/draft_store.dart';
import '../features/library/library_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 1;
  Draft? _draftToOpen;

  void _handleOpenDraft(Draft draft) {
    setState(() {
      _draftToOpen = draft;
      _index = 1; // Força a ida para a aba do Creator
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        // Removido o 'const' para permitir passagem de propriedades dinâmicas
        children: [
          const HallPage(),
          CreatorPage(
            pendingDraft: _draftToOpen,
            onDraftConsumed: () {
              // Limpa o draft após consumido para não reaplicar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _draftToOpen != null) {
                  setState(() => _draftToOpen = null);
                }
              });
            },
          ),
          LibraryPage(
            onOpenDraft: _handleOpenDraft,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Hall',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Creator',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
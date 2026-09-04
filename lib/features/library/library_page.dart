import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import 'draft_store.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    DraftStore.version.addListener(_refresh);
  }

  @override
  void dispose() {
    DraftStore.version.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final drafts = DraftStore.drafts;
    debugPrint('Library build: ${drafts.length} rascunhos');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library (${drafts.length})',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rascunhos salvos neste computador.',
              style: TextStyle(fontSize: 14, color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: drafts.isEmpty
                  ? const Text(
                      'Nada salvo ainda. No Creator, monte um card e toque em Salvar na Library.',
                      style: TextStyle(color: AppTheme.muted),
                    )
                  : ListView.separated(
                      itemCount: drafts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.title.isEmpty ? 'Sem título' : draft.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (draft.artist.isNotEmpty) draft.artist,
                                  if (draft.audioName != null) draft.audioName!,
                                  '${draft.selectedLines.length} linhas no card',
                                ].join('  ·  '),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
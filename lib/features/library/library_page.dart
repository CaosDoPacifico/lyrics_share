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

  Future<void> _confirmRemove(Draft draft) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Remover rascunho?'),
          content: Text(draft.title.isEmpty ? 'Sem título' : draft.title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await DraftStore.remove(draft.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drafts = DraftStore.drafts;

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
              'Toque no item para editar. Lixeira para remover.',
              style: TextStyle(fontSize: 14, color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: drafts.isEmpty
                  ? const Text(
                      'Nada salvo ainda.',
                      style: TextStyle(color: AppTheme.muted),
                    )
                  : ListView.separated(
                      itemCount: drafts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        return Material(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                            onTap: () => DraftStore.openInCreator(draft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: Color(0x22FFFFFF)),
                            ),
                            title: Text(
                              draft.title.isEmpty ? 'Sem título' : draft.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (draft.artist.isNotEmpty) draft.artist,
                                if (draft.audioName != null) draft.audioName!,
                                '${draft.selectedLines.length} linhas no card',
                              ].join('  ·  '),
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                            trailing: IconButton(
                              onPressed: () => _confirmRemove(draft),
                              icon: const Icon(Icons.delete_outline),
                              color: AppTheme.muted,
                            ),
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
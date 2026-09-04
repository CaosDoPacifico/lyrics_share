import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../app/app_theme.dart';
import '../library/draft_store.dart';

class CreatorPage extends StatefulWidget {
  const CreatorPage({
    super.key,
    this.pendingDraft,
    this.onDraftConsumed,
  });

  final Draft? pendingDraft;
  final VoidCallback? onDraftConsumed;

  @override
  State<CreatorPage> createState() => _CreatorPageState();
}

class _CreatorPageState extends State<CreatorPage> {
  static const int maxSelectedLines = 6;

  final GlobalKey _cardKey = GlobalKey();

  String? _appliedDraftId;
  String? title;
  String? artist;
  String? lyrics;
  PlatformFile? audioFile;
  int? rangeStart;
  int? rangeEnd;
  int? anchor;
  bool _exporting = false;

  bool get hasSong => title != null && title!.trim().isNotEmpty;
  bool get hasAudio => audioFile != null;
  bool get hasExcerpt => selectedLyricText.isNotEmpty;

  @override
  void didUpdateWidget(covariant CreatorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDraft = widget.pendingDraft;
    if (newDraft != null && newDraft.id != _appliedDraftId) {
      _applyDraft(newDraft);
    }
  }

  void _applyDraft(Draft draft) {
    setState(() {
      _appliedDraftId = draft.id;
      title = draft.title;
      artist = draft.artist;
      lyrics = draft.lyrics;
      audioFile = null; 
      
      if (draft.selectedLines.isNotEmpty) {
        rangeStart = draft.selectedLines.first;
        rangeEnd = draft.selectedLines.last;
        anchor = rangeStart;
      } else {
        rangeStart = null;
        rangeEnd = null;
        anchor = null;
      }
    });
    widget.onDraftConsumed?.call();
  }

  List<String> get lyricLines {
    if (lyrics == null || lyrics!.trim().isEmpty) return const [];
    return lyrics!.split('\n');
  }

  List<int> get selectedIndexes {
    if (rangeStart == null || rangeEnd == null) return const [];
    return [for (var i = rangeStart!; i <= rangeEnd!; i++) i];
  }

  List<String> get selectedLyricText {
    final lines = lyricLines;
    return [
      for (final index in selectedIndexes)
        if (index >= 0 && index < lines.length && lines[index].trim().isNotEmpty)
          lines[index],
    ];
  }

  int _selectableCount(int start, int end) {
    final lines = lyricLines;
    var count = 0;
    for (var i = start; i <= end; i++) {
      if (i >= 0 && i < lines.length && lines[i].trim().isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  (int, int) _clampRange(int from, int to) {
    final lines = lyricLines;
    if (to >= from) {
      var count = 0;
      var end = from;
      for (var i = from; i <= to && i < lines.length; i++) {
        if (lines[i].trim().isEmpty) {
          end = i;
          continue;
        }
        if (count + 1 > maxSelectedLines) break;
        count++;
        end = i;
      }
      return (from, end);
    }

    var count = 0;
    var start = from;
    for (var i = from; i >= to && i >= 0; i--) {
      if (lines[i].trim().isEmpty) {
        start = i;
        continue;
      }
      if (count + 1 > maxSelectedLines) break;
      count++;
      start = i;
    }
    return (start, from);
  }

  void _onLineTap(int index) {
    if (lyricLines[index].trim().isEmpty) return;

    setState(() {
      if (anchor == null || (rangeStart == index && rangeEnd == index)) {
        if (anchor == index && rangeStart == index && rangeEnd == index) {
          anchor = null;
          rangeStart = null;
          rangeEnd = null;
          return;
        }
        anchor = index;
        rangeStart = index;
        rangeEnd = index;
        return;
      }

      final clamped = _clampRange(anchor!, index);
      rangeStart = clamped.$1;
      rangeEnd = clamped.$2;
    });
  }

  Future<void> _addSong() async {
    final titleController = TextEditingController(text: title);
    final artistController = TextEditingController(text: artist);
    final lyricsController = TextEditingController(text: lyrics);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Adicionar música'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(labelText: 'Artista'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lyricsController,
                  minLines: 6,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Letra',
                    alignLabelWithHint: true,
                    hintText: 'Cola a letra aqui',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      setState(() {
        title = titleController.text.trim();
        artist = artistController.text.trim();
        lyrics = lyricsController.text;
        anchor = null;
        rangeStart = null;
        rangeEnd = null;
      });
    }

    titleController.dispose();
    artistController.dispose();
    lyricsController.dispose();
  }

  Future<void> _addAudio() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav'],
    );

    if (file == null) return;

    setState(() {
      audioFile = file;
    });
  }

  Future<void> _exportCard() async {
    if (!hasExcerpt || _exporting) return;

    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    setState(() => _exporting = true);

    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final rawName = (title ?? 'lyrics-share').trim();
      final fileName = '${rawName.isEmpty ? 'lyrics-share' : rawName}.png';

      await FilePicker.saveFile(
        dialogTitle: 'Salvar card',
        fileName: fileName,
        bytes: bytes,
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _showMessage(String text) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          content: Text(text),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveDraft() async {
    if (!hasSong) {
      await _showMessage('Adiciona a música primeiro.');
      return;
    }

    try {
      final draftId = _appliedDraftId ?? DateTime.now().millisecondsSinceEpoch.toString();

      await DraftStore.save(
        Draft(
          id: draftId,
          title: title ?? '',
          artist: artist ?? '',
          lyrics: lyrics ?? '',
          selectedLines: selectedIndexes,
          audioName: audioFile?.name,
          createdAt: DateTime.now(),
        ),
      );
      
      if (mounted) {
        setState(() {
          _appliedDraftId = draftId;
        });
      }

      await _showMessage('Salvo na Library.');
    } catch (error) {
      await _showMessage('Salvou na sessão, disco falhou:\n$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = lyricLines;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Creator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasExcerpt
                  ? '${_selectableCount(rangeStart!, rangeEnd!)} / $maxSelectedLines linhas'
                  : 'Selecione até $maxSelectedLines linhas seguidas.',
              style: const TextStyle(fontSize: 14, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              child: hasSong
                  ? Text(
                      [
                        title!,
                        if (artist?.isNotEmpty == true) artist!,
                        if (hasAudio) audioFile!.name,
                      ].join('  ·  '),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.text,
                      ),
                    )
                  : const Text(
                      'Nenhuma música ainda.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: lines.isEmpty
                  ? const _InfoCard(
                      child: _EmptyBlock(
                        title: 'Sem letra',
                        subtitle:
                            'Adiciona a letra pra escolher o trecho do card.',
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _InfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Letra',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: lines.length,
                                    itemBuilder: (context, index) {
                                      final line = lines[index];
                                      final selected = rangeStart != null &&
                                          rangeEnd != null &&
                                          index >= rangeStart! &&
                                          index <= rangeEnd!;
                                      if (line.trim().isEmpty) {
                                        return const SizedBox(height: 10);
                                      }
                                      return InkWell(
                                        onTap: () => _onLineTap(index),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? const Color(0x33D4B483)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            line,
                                            style: TextStyle(
                                              color: selected
                                                  ? AppTheme.text
                                                  : AppTheme.muted,
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: RepaintBoundary(
                                key: _cardKey,
                                child: _LyricCard(
                                  title: title ?? 'Sem título',
                                  artist: artist?.isNotEmpty == true
                                      ? artist!
                                      : 'Artista não informado',
                                  lines: selectedLyricText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: _addSong,
                      child: Text(
                        hasSong ? 'Editar música' : 'Adicionar música',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _addAudio,
                      child: Text(hasAudio ? 'Trocar áudio' : 'Adicionar áudio'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.tonal(
                      onPressed: hasExcerpt && !_exporting ? _exportCard : null,
                      child: Text(_exporting ? 'Exportando...' : 'Exportar card'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _saveDraft,
                      child: const Text('Salvar na Library'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LyricCard extends StatelessWidget {
  const _LyricCard({
    required this.title,
    required this.artist,
    required this.lines,
  });

  final String title;
  final String artist;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF17191F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            artist,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: 18),
          if (lines.isEmpty)
            const Text(
              'Toque nas linhas à esquerda para montar o trecho.',
              style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.4),
            )
          else
            Text(
              lines.join('\n'),
              style: const TextStyle(
                fontSize: 18,
                height: 1.45,
                color: AppTheme.text,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: child,
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppTheme.muted),
        ),
      ],
    );
  }
}
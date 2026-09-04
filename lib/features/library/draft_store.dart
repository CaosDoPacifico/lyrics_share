import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Draft {
  Draft({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyrics,
    required this.selectedLines,
    this.audioName,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String artist;
  final String lyrics;
  final List<int> selectedLines;
  final String? audioName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'lyrics': lyrics,
      'selectedLines': selectedLines,
      'audioName': audioName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      lyrics: json['lyrics'] as String? ?? '',
      selectedLines: [
        for (final item in (json['selectedLines'] as List? ?? const []))
          item as int,
      ],
      audioName: json['audioName'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class DraftStore {
  static final ValueNotifier<int> version = ValueNotifier(0);
  static final List<Draft> drafts = [];

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/drafts.json');
  }

  static Future<void> _persist() async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode([for (final item in drafts) item.toJson()]),
    );
  }

  static Future<void> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;

      final raw = jsonDecode(await file.readAsString());
      drafts
        ..clear()
        ..addAll([
          for (final item in raw as List)
            Draft.fromJson(item as Map<String, dynamic>),
        ]);
      version.value++;
    } catch (error, stack) {
      debugPrint('DraftStore.load failed: $error');
      debugPrint('$stack');
    }
  }

  // Novo método Save (substitui o add)
  static Future<void> save(Draft draft) async {
    final index = drafts.indexWhere((item) => item.id == draft.id);
    
    if (index >= 0) {
      drafts[index] = draft; // Atualiza o existente
    } else {
      drafts.insert(0, draft); // Insere como novo
    }
    
    version.value++;
    await _persist();
  }

  static Future<void> remove(String id) async {
    drafts.removeWhere((item) => item.id == id);
    version.value++;
    await _persist();
  }
}
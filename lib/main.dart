import 'package:flutter/material.dart';
import 'app/app.dart';
import 'features/library/draft_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DraftStore.load();
  runApp(const LyricsShareApp());
}
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_shell.dart';

class LyricsShareApp extends StatelessWidget {
  const LyricsShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyrics Share',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
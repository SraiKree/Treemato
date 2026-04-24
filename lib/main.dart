import 'package:flutter/material.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TreematoApp());
}

class TreematoApp extends StatelessWidget {
  const TreematoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Treemato',
      theme: buildTreematoTheme(),
      home: const MainShell(),
    );
  }
}

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/editor/presentation/screens/editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LayerlyApp());
}

class LayerlyApp extends StatelessWidget {
  const LayerlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Layerly - Offline Visual Content Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const EditorScreen(),
    );
  }
}

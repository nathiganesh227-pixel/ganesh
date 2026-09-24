import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/plaza_theme.dart';
import 'features/navigation/plaza_navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set dark immersive status bar and navigation bar styles
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PlazaApp());
}

class PlazaApp extends StatelessWidget {
  const PlazaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLAZA',
      debugShowCheckedModeBanner: false,
      theme: PlazaTheme.darkTheme,
      home: const PlazaNavigationShell(),
    );
  }
}

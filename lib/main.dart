import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Global static notifier to change themes from anywhere in the app
  static final ValueNotifier<ThemeMode> themeNotifier = 
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Try Prompt',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          // YouTube-like Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFFFF0000), // YouTube Red
            scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0F0F0F),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF0000),
              secondary: Color(0xFFFF0000),
              surface: Colors.white,
              surfaceTint: Colors.transparent,
            ),
          ),

          // YouTube-like Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFFF0000), // YouTube Red
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F0F0F),
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF0000),
              secondary: Color(0xFFFF0000),
              surface: Color(0xFF1F1F1F),
              surfaceTint: Colors.transparent,
            ),
          ),
          
          initialRoute: '/',
          routes: {
            '/': (context) => MainScreen(
                  themeMode: currentMode,
                  onThemeChanged: (mode) {
                    MyApp.themeNotifier.value = mode;
                  },
                ),
          },
        );
      },
    );
  }
}

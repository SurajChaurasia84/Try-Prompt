import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/mainscreen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final prefs = await SharedPreferences.getInstance();
  final String? savedTheme = prefs.getString('theme_mode');
  ThemeMode initialTheme = ThemeMode.system;
  if (savedTheme == 'dark') {
    initialTheme = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    initialTheme = ThemeMode.light;
  }
  MyApp.themeNotifier.value = initialTheme;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Global static notifier to change themes from anywhere in the app
  static final ValueNotifier<ThemeMode> themeNotifier = 
      ValueNotifier<ThemeMode>(ThemeMode.system);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final bool isUnderTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Try Prompt',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          // Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFFFF0000), // Red
            scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0F0F0F),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF0000),
              secondary: Color(0xFFFF0000),
              surface: Colors.white,
              surfaceTint: Colors.transparent,
            ),
          ),

          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFFF0000), // Red
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F0F0F),
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF0000),
              secondary: Color(0xFFFF0000),
              surface: Color(0xFF1F1F1F),
              surfaceTint: Colors.transparent,
            ),
          ),
          
          home: SplashScreen(
            themeMode: currentMode,
            onThemeChanged: (mode) async {
              MyApp.themeNotifier.value = mode;
              final prefs = await SharedPreferences.getInstance();
              if (mode == ThemeMode.dark) {
                await prefs.setString('theme_mode', 'dark');
              } else if (mode == ThemeMode.light) {
                await prefs.setString('theme_mode', 'light');
              } else {
                await prefs.setString('theme_mode', 'system');
              }
            },
          ),
        );
      },
    );
  }
}

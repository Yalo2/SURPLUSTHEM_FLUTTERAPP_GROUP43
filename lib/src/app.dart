import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:surplusthem/firebase_options.dart';
import 'package:surplusthem/src/routes/app_routes.dart';
import 'package:surplusthem/src/routes/route_generator.dart';
import 'package:surplusthem/src/theme/app_theme.dart';
import 'package:surplusthem/src/theme/theme_controller.dart';

Future<void> mainDelegate() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SurplusThem',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }
}

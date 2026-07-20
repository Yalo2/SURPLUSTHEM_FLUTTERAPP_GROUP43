import 'package:flutter/material.dart';
import 'package:surplusthem/src/routes/app_routes.dart';
import 'package:surplusthem/src/screens/auth/login_screen.dart';
import 'package:surplusthem/src/screens/auth/register_screen.dart';
import 'package:surplusthem/src/screens/auth/splash_screen.dart';
import 'package:surplusthem/src/screens/dashboard/main_navigation_screen.dart';
import 'package:surplusthem/src/screens/dashboard/item_detail_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
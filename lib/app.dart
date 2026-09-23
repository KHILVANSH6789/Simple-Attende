// ============================================================
// lib/app.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/group/group_screen.dart';
import 'screens/settings/settings_screen.dart';

class SimpleAttendeApp extends StatelessWidget {
  const SimpleAttendeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Simple Attende',
            debugShowCheckedModeBanner: false,
            theme: settings.materialTheme,
            initialRoute: '/intro',
            onGenerateRoute: (routeSettings) {
              switch (routeSettings.name) {
                case '/intro':
                  return _route(const IntroScreen(), routeSettings);
                case '/home':
                  return _route(const HomeScreen(), routeSettings);
                case '/group':
                  final groupId = routeSettings.arguments as String;
                  return _route(
                      GroupScreen(groupId: groupId), routeSettings);
                case '/settings':
                  return _route(const SettingsScreen(), routeSettings);
                default:
                  return _route(const HomeScreen(), routeSettings);
              }
            },
          );
        },
      ),
    );
  }

  PageRoute _route(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

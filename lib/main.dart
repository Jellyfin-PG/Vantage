


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/prefs.dart';
import 'services/core_manager.dart';
import 'services/theme_service.dart';
import 'models/nasa_theme.dart';
import 'screens/login_screen.dart';
import 'screens/library_screen.dart';
import 'screens/cores_screen.dart';
import 'screens/emulator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CoreManager.instance.init();
  await ThemeService.instance.init();
  runApp(const VantageApp());
}

final _prefs = Prefs();

final _router = GoRouter(
  initialLocation: '/loading',
  routes: [
    GoRoute(
      path: '/loading',
      builder: (_, __) => const _SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/library',
      builder: (_, __) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/cores',
      builder: (_, __) => const CoresScreen(),
    ),
    GoRoute(
      path: '/emulator',
      builder: (_, state) {
        final args = state.extra as Map<String, dynamic>;
        return EmulatorScreen(
          romPath: args['romPath'] as String,
          corePath: args['corePath'] as String,
          title: args['title'] as String,
          itemId: args['itemId'] as String?,
          serverUrl: args['serverUrl'] as String,
          token: args['token'] as String,
          userId: args['userId'] as String,
        );
      },
    ),
  ],
);

class VantageApp extends StatelessWidget {
  const VantageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final nasaTheme = ThemeService.instance.currentTheme;
        
        return MaterialApp.router(
          title: 'Vantage',
          debugShowCheckedModeBanner: false,
          theme: _buildDynamicNasaTheme(nasaTheme),
          routerConfig: _router,
        );
      },
    );
  }

  ThemeData _buildDynamicNasaTheme(NasaTheme nt) {
    return ThemeData(
      useMaterial3: true,
      brightness: nt.brightness,
      scaffoldBackgroundColor: nt.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: nt.primary,
        brightness: nt.brightness,
        primary: nt.primary,
        surface: nt.surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: nt.brightness == Brightness.dark ? const Color(0xFF1A1A1A).withOpacity(0.5) : Colors.white.withOpacity(0.5),
        foregroundColor: nt.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: nt.text,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: nt.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: nt.text.withOpacity(0.05)),
        ),
      ),
      dividerColor: nt.text.withOpacity(0.1),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: nt.text),
        bodyMedium: TextStyle(color: nt.text),
        bodySmall: TextStyle(color: nt.text.withOpacity(0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: nt.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }
}


class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final loggedIn = await _prefs.isLoggedIn;
    if (!mounted) return;
    if (loggedIn) {
      context.go('/library');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nasaTheme = ThemeService.instance.currentTheme;
    return Scaffold(
      backgroundColor: nasaTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch, size: 72, color: nasaTheme.primary),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: nasaTheme.primary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}


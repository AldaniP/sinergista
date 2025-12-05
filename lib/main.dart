import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/update_password_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/tasks/dashboard_screen.dart';
import 'features/academic/notes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Sinergista',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: {'/notes': (_) => const NotesScreen()},
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _showOnboarding = false;
  bool _isLoggedIn = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndOnboarding();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    bool loggedIn = false;
    if (session != null) {
      if (rememberMe) {
        loggedIn = true;
      } else {
        // Session exists but remember me is false (e.g. didn't log out properly or preference changed)
        // Force strict logout or just ignore session for auto-login
        // Let's clear just to be safe if desired, but user might just want to re-enter password.
        // For "Remember Me" pattern, usually we just don't auto-navigate.
        // Option: Supabase persistence is on by default. checking rememberMe allows us to decide.
        // If we want to force login, we treat as not logged in.
      }
    }

    if (mounted) {
      setState(() {
        _showOnboarding = !onboardingCompleted;
        _isLoggedIn = loggedIn;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showOnboarding) return const OnboardingScreen();
    if (_isLoggedIn) return const DashboardScreen();
    return const LoginScreen();
  }
}

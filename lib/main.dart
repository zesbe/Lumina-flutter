import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  
  final playerProvider = PlayerProvider();
  await playerProvider.init();
  
  runApp(MyApp(
    playerProvider: playerProvider,
    showOnboarding: !onboardingComplete,
  ));
}

class MyApp extends StatefulWidget {
  final PlayerProvider playerProvider;
  final bool showOnboarding;
  
  const MyApp({super.key, required this.playerProvider, required this.showOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider.value(value: widget.playerProvider),
      ],
      child: MaterialApp(
        title: 'Lumina AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          primaryColor: const Color(0xFF84CC16),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF84CC16),
            secondary: Color(0xFF22C55E),
            surface: Color(0xFF1A1A1A),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: _showOnboarding 
            ? OnboardingScreen(onComplete: () => setState(() => _showOnboarding = false))
            : const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) return const SplashScreen();
    if (auth.isAuthenticated) return const MainScreen();
    return const LoginScreen();
  }
}

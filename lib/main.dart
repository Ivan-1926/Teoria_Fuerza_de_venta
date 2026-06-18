import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'providers/providers.dart';
import 'providers/auth_notifier.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Trigger automatic session recovery on startup
    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).recoverSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    Widget homeWidget;
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        homeWidget = const _SplashScreen();
        break;
      case AuthStatus.authenticated:
        homeWidget = const HomeShell();
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        homeWidget = const LoginScreen();
        break;
    }

    return MaterialApp(
      title: 'Asesor Ventas',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: homeWidget,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF001F4D), Color(0xFF003F7D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kBrandWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.support_agent,
                  size: 45,
                  color: kPrimaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ASESOR VENTAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Banco Pichincha',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: kBrandWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

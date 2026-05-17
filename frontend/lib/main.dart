import 'package:flutter/material.dart';

import 'screens/create_group_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_groups_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelPick',
      theme: AppTheme.lightTheme,
      home: const AppBootstrap(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        CreateGroupScreen.routeName: (_) => const CreateGroupScreen(),
        MyGroupsScreen.routeName: (_) => const MyGroupsScreen(),
      },
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _resolveStartScreen();
  }

  Future<void> _resolveStartScreen() async {
    final restoredUser = await AuthService.instance.tryRestoreSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _initialScreen = restoredUser != null
          ? const HomeScreen()
          : const WelcomeScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialScreen == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _initialScreen!;
  }
}

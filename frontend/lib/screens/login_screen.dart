import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _saveAccount = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        saveAccount: _saveAccount,
      );
      if (!mounted) {
        return;
      }
      replaceWithAppPage(context, const HomeScreen());
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    await AuthService.instance.continueAsGuest();
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    replaceWithAppPage(context, const HomeScreen());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              AnimatedReveal(
                child: Row(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.deepTeal,
                        fixedSize: const Size(46, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AnimatedReveal(
                child: Text(
                  'Welcome to TravelPick',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedReveal(
                delay: const Duration(milliseconds: 70),
                child: Text(
                  'Welcome back! Sign in to pick up where your groups left off.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 28),
              AnimatedReveal(
                delay: const Duration(milliseconds: 120),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return 'Enter your email.';
                          }
                          if (!email.contains('@')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Enter your password.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _logIn(),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: _saveAccount,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() => _saveAccount = value ?? false);
                              },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Save account for next login'),
                        subtitle: const Text(
                          'Stay signed in on this device.',
                          style: TextStyle(fontSize: 13),
                        ),
                        activeColor: AppTheme.teal,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedReveal(
                delay: const Duration(milliseconds: 180),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _logIn,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log In'),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedReveal(
                delay: const Duration(milliseconds: 220),
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => pushAppPage(context, const SignupScreen()),
                  child: const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedReveal(
                delay: const Duration(milliseconds: 260),
                child: TextButton(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  child: const Text('Continue as Guest'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    _showMessage('Password reset will be available soon.');
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Text(
                  'Demo account: demo@travelpick.com / demo123',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

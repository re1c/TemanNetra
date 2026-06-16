import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import 'signup_screen.dart';

/// Layar masuk utama yang dioptimalkan untuk aksesibilitas tunanetra.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan state secara pasif untuk memicu pesan error 
    // di luar siklus rendering widget (mencegah efek samping penulisan state saat build).
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, _) {
            final cleanMessage = error.toString().replaceAll('Exception: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(cleanMessage),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pembungkus Semantics memberikan petunjuk suara verbal bagi 
                // pengguna TalkBack/VoiceOver mengenai fungsi elemen input.
                Semantics(
                  label: 'Email Input Field',
                  hint: 'Double tap to type your email address',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Password Input Field',
                  hint: 'Double tap to type your password',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Sign In Button',
                  hint: 'Double tap to authenticate and access your account',
                  button: true,
                  child: SizedBox(
                    height: 56, // Tinggi minimum yang aman untuk tap target aksesibilitas
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                ref.read(authControllerProvider.notifier).signIn(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Navigate to Sign Up Screen Link',
                  hint: 'Double tap if you do not have an account and want to register',
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                    child: const Text('Don\'t have an account? Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

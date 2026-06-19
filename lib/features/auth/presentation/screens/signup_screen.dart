import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';
import '../controllers/auth_controller.dart';

/// Layar registrasi pengguna baru dengan seleksi peran (Tunanetra vs Relawan).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.tunanetra;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authMutationControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pendaftaran berhasil! Akun Anda telah aktif.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
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

    final authMutationState = ref.watch(authMutationControllerProvider);
    final isLoading = authMutationState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
                Semantics(
                  label: 'Full Name Input Field',
                  hint: 'Double tap to type your full name',
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
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
                  hint: 'Double tap to type a secure password',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Judul area pemilihan peran untuk memandu pengguna pembaca layar
                Semantics(
                  label: 'Select User Role Area',
                  child: const Text(
                    'I want to register as:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Desain Card Premium Kontras Tinggi yang mendukung Aksesibilitas
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Register as Visually Impaired Option',
                        hint: 'Select this if you need assistant features',
                        selected: _selectedRole == UserRole.tunanetra,
                        button: true,
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRole = UserRole.tunanetra;
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedRole == UserRole.tunanetra
                                    ? const Color(0xFFFFD700)
                                    : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.visibility_off, size: 32),
                                SizedBox(height: 8),
                                Text('Tunanetra', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Semantics(
                        label: 'Register as Volunteer Helper Option',
                        hint: 'Select this if you want to assist others',
                        selected: _selectedRole == UserRole.volunteer,
                        button: true,
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRole = UserRole.volunteer;
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedRole == UserRole.volunteer
                                    ? const Color(0xFFFFD700)
                                    : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.handshake, size: 32),
                                SizedBox(height: 8),
                                Text('Volunteer', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Semantics(
                  label: 'Create Account Button',
                  hint: 'Double tap to submit registration details and create your profile',
                  button: true,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                ref.read(authMutationControllerProvider.notifier).signUp(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      name: _nameController.text.trim(),
                                      role: _selectedRole,
                                    );
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Create Account',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
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

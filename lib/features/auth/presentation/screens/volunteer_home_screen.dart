import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

/// Halaman beranda sementara untuk pengguna relawan.
class VolunteerHomeScreen extends ConsumerWidget {
  const VolunteerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
        actions: [
          Semantics(
            label: 'Sign Out Button',
            hint: 'Double tap to log out of your account',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Semantics(
          label: 'Welcome to Volunteer Dashboard. Volunteer mode activated.',
          focused: true,
          child: const Text(
            'Volunteer Mode Active\n(Fase 4 Dashboard)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

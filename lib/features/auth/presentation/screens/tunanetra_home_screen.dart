import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

/// Halaman beranda sementara untuk pengguna disabilitas netra.
class TunanetraHomeScreen extends ConsumerWidget {
  const TunanetraHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TemanNetra Home'),
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
          label: 'Welcome to TemanNetra Home Page. Tunanetra mode activated.',
          focused: true,
          child: const Text(
            'Tunanetra Mode Active\n(Fase 3 Assistive Features)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Color(0xFFFFD700)),
          ),
        ),
      ),
    );
  }
}

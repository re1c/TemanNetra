import 'package:flutter/material.dart';
import 'package:temannetra/features/volunteer/presentation/screens/volunteer_dashboard_screen.dart';

/// Halaman beranda untuk pengguna relawan.
///
/// Layar ini menjadi entry point role relawan dari auth flow, lalu mendelegasikan
/// tampilan utama ke modul volunteer agar struktur feature-first tetap terjaga.
class VolunteerHomeScreen extends StatelessWidget {
  const VolunteerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VolunteerDashboardScreen();
  }
}
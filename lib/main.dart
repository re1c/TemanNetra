import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'features/auth/domain/models/user_model.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/tunanetra_home_screen.dart';
import 'features/auth/presentation/screens/volunteer_home_screen.dart';
import 'features/auth/presentation/screens/admin_verification_dashboard_screen.dart';

import 'package:temannetra/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  runApp(
    const ProviderScope(
      child: TemanNetraApp(),
    ),
  );
}

class TemanNetraApp extends ConsumerWidget {
  const TemanNetraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inisialisasi layanan notifikasi FCM saat aplikasi dimulai
    ref.watch(notificationServiceProvider);

    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TemanNetra',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700),
          brightness: Brightness.dark,
          primary: const Color(0xFFFFD700),
          surface: const Color(0xFF121212),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      routes: {
        '/tunanetra_home': (context) => const TunanetraHomeScreen(),
      },
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }

          if (user.role == UserRole.tunanetra) {
            return const TunanetraHomeScreen();
          }

          if (user.role == UserRole.admin) {
            return const AdminVerificationDashboardScreen();
          }

          return const VolunteerHomeScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Scaffold(
          body: Center(
            child: Semantics(
              label: 'Terjadi kesalahan sistem: $error',
              focused: true,
              child: Text(
                'System Error\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
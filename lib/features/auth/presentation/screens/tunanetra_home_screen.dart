import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../help_request/presentation/controllers/help_request_controller.dart';
import '../../../help_request/presentation/screens/help_request_detail_screen.dart';
import '../../../help_request/presentation/screens/help_request_history_screen.dart';
import '../controllers/auth_controller.dart';

class TunanetraHomeScreen extends ConsumerStatefulWidget {
  const TunanetraHomeScreen({super.key});

  @override
  ConsumerState<TunanetraHomeScreen> createState() =>
      _TunanetraHomeScreenState();
}

class _TunanetraHomeScreenState extends ConsumerState<TunanetraHomeScreen> {
  static const Color _backgroundColor = Color(0xFF0F0F0F);
  static const Color _cardColor = Color(0xFF1B1B1B);
  static const Color _primaryYellow = Color(0xFFFFD700);

  void _openAiAssistant() {
    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak(
          'Membuka Asisten AI untuk membantu mengenali objek dan teks.',
        );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AiAssistantScreen(),
      ),
    );
  }

  Future<void> _requestVolunteerHelp() async {
    final isLoading = ref.read(helpRequestControllerProvider).isLoading;
    if (isLoading) {
      return;
    }

    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak(
          'Membuat permintaan bantuan relawan. Mohon tunggu sebentar.',
        );

    try {
      final ticket = await ref
          .read(helpRequestControllerProvider.notifier)
          .getOrCreateActiveHelpRequest();

      if (!mounted) {
        return;
      }

      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak(
            'Permintaan bantuan relawan berhasil dibuka.',
          );

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HelpRequestDetailScreen(ticket: ticket),
        ),
      );
    } catch (e) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak(
            'Gagal membuat permintaan bantuan relawan.',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal meminta bantuan relawan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openHelpHistory() {
    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak(
          'Membuka daftar bantuan saya.',
        );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HelpRequestHistoryScreen(),
      ),
    );
  }

  Future<void> _signOut() async {
    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak('Keluar dari akun Anda.');
    await ref.read(authMutationControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text(
          'TemanNetra',
          style: TextStyle(
            color: _primaryYellow,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Semantics(
              label: 'Tombol keluar akun',
              hint: 'Ketuk dua kali untuk keluar dari akun Anda.',
              button: true,
              child: TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Keluar',
                  style: TextStyle(
                    color: _primaryYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Semantics(
              label:
                  'Selamat datang di TemanNetra. Pilih Asisten AI atau Bantuan Relawan.',
              focused: true,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, TemanNetra',
                    style: TextStyle(
                      color: _primaryYellow,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pilih bantuan yang Anda butuhkan.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _LargeHomeActionCard(
              height: 245,
              title: 'Buka\nAsisten AI',
              description:
                  'Gunakan kamera untuk mengenali objek dan membaca teks di sekitar Anda.',
              backgroundColor: _primaryYellow,
              foregroundColor: Colors.black,
              borderColor: _primaryYellow,
              semanticLabel:
                  'Buka Asisten AI. Gunakan kamera untuk mengenali objek dan membaca teks di sekitar Anda.',
              isLoading: false,
              onPressed: _openAiAssistant,
            ),
            const SizedBox(height: 18),
            _LargeHomeActionCard(
              height: 245,
              title: 'Minta Bantuan\nRelawan',
              description:
                  'Tekan sekali untuk langsung membuat permintaan bantuan relawan.',
              backgroundColor: _cardColor,
              foregroundColor: _primaryYellow,
              borderColor: _primaryYellow,
              semanticLabel:
                  'Minta bantuan relawan. Tombol ini langsung membuat permintaan bantuan.',
              isLoading: ref.watch(helpRequestControllerProvider).isLoading,
              onPressed: _requestVolunteerHelp,
            ),
            const SizedBox(height: 18),
            _HistoryBarButton(
              onPressed: _openHelpHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeHomeActionCard extends StatelessWidget {
  final double height;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final String semanticLabel;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LargeHomeActionCard({
    required this.height,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.semanticLabel,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: 'Ketuk dua kali untuk membuka.',
      button: true,
      child: SizedBox(
        height: height,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: isLoading ? null : onPressed,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: borderColor,
                  width: 2.5,
                ),
              ),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: foregroundColor,
                        strokeWidth: 4,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foregroundColor.withAlpha(220),
                            fontSize: 17,
                            height: 1.28,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryBarButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HistoryBarButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daftar bantuan saya',
      hint: 'Ketuk dua kali untuk melihat riwayat dan status bantuan Anda.',
      button: true,
      child: SizedBox(
        height: 72,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFD700),
            side: const BorderSide(
              color: Color(0xFFFFD700),
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'Daftar Bantuan Saya',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
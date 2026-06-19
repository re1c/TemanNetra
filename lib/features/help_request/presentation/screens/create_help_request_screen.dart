import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../../ai_assistant/presentation/controllers/ai_assistant_controller.dart';
import '../controllers/help_request_controller.dart';

/// Layar pembuatan pengajuan tiket bantuan baru khusus tunanetra.
///
/// Menyediakan tombol integrasi cerdas untuk menyalin hasil pemindaian Gemini AI
/// terakhir secara otomatis (AI Bridge) guna mempermudah input tanpa keyboard visual.
class CreateHelpRequestScreen extends ConsumerStatefulWidget {
  const CreateHelpRequestScreen({super.key});

  @override
  ConsumerState<CreateHelpRequestScreen> createState() => _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState extends ConsumerState<CreateHelpRequestScreen> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Salam audio pembuka panduan layar pengajuan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
        'Layar buat tiket bantuan baru. Silakan ketik deskripsi bantuan Anda, '
        'atau ketuk tombol salin hasil kamera di bagian atas jika sudah memotret objek.'
      );
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Fitur Integrasi AI Bridge: Menyalin hasil pemindaian Gemini terakhir ke form.
  void _copyLastAiResult() {
    final aiState = ref.read(aiAssistantControllerProvider);
    final aiResult = aiState.valueOrNull;

    if (aiResult != null) {
      ref.read(hapticServiceProvider).vibrateSuccess();
      final scene = aiResult.sceneDescription;
      final text = aiResult.text;
      
      // Gabungkan deskripsi objek dengan teks terbaca jika ada
      final fullText = text.isNotEmpty ? '$scene. Terbaca teks: $text' : scene;
      
      setState(() {
        _descriptionController.text = fullText;
      });

      ref.read(ttsServiceProvider).speak('Berhasil menyalin hasil kamera cerdas.');
    } else {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak(
        'Salin gagal. Tidak ditemukan riwayat pemindaian kamera terakhir. '
        'Silakan ketik manual atau buka modul asisten AI terlebih dahulu.'
      );
    }
  }

  /// Mengeksekusi pengajuan tiket bantuan baru ke Firestore.
  Future<void> _submitRequest() async {
    final isLoading = ref.read(helpRequestControllerProvider).isLoading;
    if (!_formKey.currentState!.validate() || isLoading) return;

    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak('Sedang mengirimkan tiket bantuan...');

    try {
      await ref
          .read(helpRequestControllerProvider.notifier)
          .createTicket(_descriptionController.text.trim());

      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak(
        'Tiket bantuan berhasil diajukan. '
        'Mohon tunggu relawan mengambil tiket Anda. '
        'Mengarahkan Anda kembali ke halaman daftar.'
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(helpRequestControllerProvider).isLoading;

    ref.listen(
      helpRequestControllerProvider,
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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Semantics(
          label: 'Tombol Batal',
          hint: 'Ketuk dua kali untuk membatalkan pembuatan tiket bantuan dan kembali',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFFFD700), size: 32),
            onPressed: () {
              ref.read(hapticServiceProvider).vibrateClick();
              ref.read(ttsServiceProvider).stop();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: const Text(
          'Minta Bantuan',
          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
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
                // Tombol AI Bridge kontras tinggi WCAG 2.2
                Semantics(
                  label: 'Tombol Salin Hasil Pindai Kamera AI',
                  hint: 'Ketuk dua kali untuk mengisi formulir secara otomatis menggunakan hasil kamera terakhir.',
                  button: true,
                  child: SizedBox(
                    height: 72,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : _copyLastAiResult,
                      icon: const Icon(Icons.copy, color: Color(0xFFFFD700), size: 28),
                      label: const Text(
                        'Salin Hasil Kamera AI',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Area input deskripsi berukuran besar
                Semantics(
                  label: 'Kolom input deskripsi bantuan',
                  hint: 'Ketik dua kali untuk mengetik secara spesifik apa yang perlu relawan bantu untuk Anda.',
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Apa yang Anda butuhkan?',
                      labelStyle: TextStyle(color: Color(0xFFFFD700)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFD700)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                      ),
                      prefixIcon: Icon(Icons.help_center, color: Color(0xFFFFD700)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harap masukkan deskripsi bantuan.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 48),

                // Tombol Kirim berukuran sangat lapang
                Semantics(
                  label: 'Tombol Ajukan Tiket Bantuan',
                  hint: 'Ketuk dua kali untuk mengirimkan pengajuan bantuan Anda ke Firestore.',
                  button: true,
                  child: SizedBox(
                    height: 80,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: isLoading ? null : _submitRequest,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'KIRIM TIKET BANTUAN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
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

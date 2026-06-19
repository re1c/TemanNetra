import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../domain/models/help_request_model.dart';
import '../controllers/help_request_controller.dart';

/// Layar perubahan (edit) deskripsi tiket bantuan tunanetra.
///
/// Menyediakan validasi UI defensif untuk memastikan tiket yang sudah diklaim
/// tidak dapat diedit kembali guna menjaga konsistensi alur kerja relawan.
class EditHelpRequestScreen extends ConsumerStatefulWidget {
  final HelpRequestModel helpRequest;

  const EditHelpRequestScreen({
    super.key,
    required this.helpRequest,
  });

  @override
  ConsumerState<EditHelpRequestScreen> createState() => _EditHelpRequestScreenState();
}

class _EditHelpRequestScreenState extends ConsumerState<EditHelpRequestScreen> {
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.helpRequest.description);
    
    // Suara panduan membuka layar edit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
        'Layar ubah tiket bantuan. Silakan edit teks deskripsi pada kolom input '
        'lalu ketuk simpan perubahan di bagian bawah.'
      );
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Mengeksekusi penyimpanan hasil perubahan ke Firestore.
  Future<void> _saveChanges() async {
    final isLoading = ref.read(helpRequestControllerProvider).isLoading;
    if (!_formKey.currentState!.validate() || isLoading) return;

    // Proteksi UI defensif: Menghalangi perubahan jika status bergeser di database
    if (widget.helpRequest.status != HelpRequestStatus.pending) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak(
        'Penyimpanan ditolak. Tiket bantuan ini sudah diklaim atau selesai dibantu.'
      );
      Navigator.of(context).pop();
      return;
    }

    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak('Sedang menyimpan perubahan tiket...');

    await ref
        .read(helpRequestControllerProvider.notifier)
        .updateTicket(widget.helpRequest.id, _descriptionController.text.trim());

    final actionState = ref.read(helpRequestControllerProvider);
    if (!actionState.hasError) {
      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak(
        'Perubahan tiket bantuan berhasil disimpan. '
        'Mengarahkan Anda kembali ke halaman daftar.'
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      helpRequestControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, _) {
            final cleanMessage = error.toString().replaceAll('Exception: ', '');
            ref.read(hapticServiceProvider).vibrateError();
            ref.read(ttsServiceProvider).speak(cleanMessage);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  cleanMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );

    final isLoading = ref.watch(helpRequestControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Semantics(
          label: 'Tombol Batal',
          hint: 'Ketuk dua kali untuk membatalkan perubahan dan kembali',
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
          'Ubah Tiket',
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
                Semantics(
                  label: 'Kolom input deskripsi bantuan yang akan diubah',
                  hint: 'Ketik dua kali untuk merubah deskripsi kebutuhan bantuan Anda.',
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Kebutuhan',
                      labelStyle: TextStyle(color: Color(0xFFFFD700)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFD700)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                      ),
                      prefixIcon: Icon(Icons.edit, color: Color(0xFFFFD700)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Deskripsi bantuan tidak boleh kosong.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 48),

                // Tombol Simpan
                Semantics(
                  label: 'Tombol Simpan Perubahan',
                  hint: 'Ketuk dua kali untuk memperbarui deskripsi tiket bantuan di Firestore.',
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
                      onPressed: isLoading ? null : _saveChanges,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'SIMPAN PERUBAHAN',
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

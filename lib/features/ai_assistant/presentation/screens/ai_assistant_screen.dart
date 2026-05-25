import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../controllers/ai_assistant_controller.dart';

/// Layar interaksi asisten AI multimodal terintegrasi kamera fisik.
///
/// Mengimplementasikan [WidgetsBindingObserver] untuk melepas/mengikat kamera secara dinamis
/// saat status aplikasi bergeser (resumed/paused) guna mengamankan sumber daya hardware OS.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitializing = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    
    // Memberikan salam audio saat pengguna membuka modul asisten cerdas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
        'Kamera asisten visual aktif. Ketuk dua kali di mana saja pada layar '
        'untuk mengambil foto dan menganalisis lingkungan Anda.'
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  /// Memantau pergeseran status aplikasi oleh sistem operasi untuk siklus hidup kamera yang aman.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // Jika aplikasi kehilangan fokus (paused/detached), segera lepas kuncian hardware
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Melakukan inisialisasi modul kamera fisik pada perangkat.
  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = '';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'Perangkat tidak memiliki kamera fisik.');
      }

      // Memilih kamera belakang utama untuk memotret objek eksternal
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium, // Resolusi cukup untuk Gemini AI demi hemat kuota data internet
        enableAudio: false,      // Menonaktifkan audio karena hanya membutuhkan frame gambar
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = _mapCameraError(e.code);
        });
        ref.read(ttsServiceProvider).speak(_errorMessage);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Gagal mengakses modul kamera. Silakan periksa izin aplikasi.';
        });
        ref.read(ttsServiceProvider).speak(_errorMessage);
      }
    }
  }

  /// Menutup koneksi dan melepas resource kamera secara eksplisit.
  void _disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  /// Menerjemahkan kode error native kamera menjadi panduan suara yang ramah tunanetra.
  String _mapCameraError(String code) {
    switch (code) {
      case 'CameraAccessDenied':
        return 'Izin akses kamera ditolak. Harap aktifkan izin kamera di pengaturan sistem perangkat Anda.';
      case 'CameraAccessRestricted':
        return 'Akses kamera dibatasi oleh kebijakan keamanan perangkat Anda.';
      default:
        return 'Kamera tidak dapat diakses. Pastikan kamera tidak sedang digunakan oleh aplikasi lain.';
    }
  }

  /// Mengambil gambar dari frame kamera dan mengirimkannya ke pengendali asisten AI.
  Future<void> _takePictureAndAnalyze() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    try {
      // Getaran pendek sebagai indikasi fisik ketukan layar terdeteksi
      ref.read(hapticServiceProvider).vibrateClick();
      
      // Memberikan feedback audio instan bahwa proses capture sedang berlangsung
      ref.read(ttsServiceProvider).speak('Sedang mengambil foto dan menganalisis. Mohon tunggu...');

      final XFile file = await controller.takePicture();
      final Uint8List imageBytes = await file.readAsBytes();

      if (mounted) {
        // Mengirim byte data ke controller asisten AI
        await ref.read(aiAssistantControllerProvider.notifier).processImage(imageBytes);
      }
    } catch (e) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak('Gagal mengambil gambar. Silakan ketuk layar kembali.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan state asisten AI secara pasif guna memicu respons suara
    ref.listen<AsyncValue<dynamic>>(
      aiAssistantControllerProvider,
      (previous, next) {
        next.when(
          data: (result) {
            if (result != null) {
              ref.read(hapticServiceProvider).vibrateSuccess();
              // Membaca deskripsi lingkungan serta teks hasil OCR dari Gemini AI
              final sceneText = result.sceneDescription.toString();
              final extractedText = result.text.toString();
              
              final String speechOutput = extractedText.isNotEmpty
                  ? '$sceneText. Terbaca teks: $extractedText'
                  : sceneText;

              ref.read(ttsServiceProvider).speak(speechOutput);
            }
          },
          error: (err, _) {
            ref.read(hapticServiceProvider).vibrateError();
            // Menyuarakan pesan kesalahan secara otomatis
            ref.read(ttsServiceProvider).speak(err.toString());
          },
          loading: () {
            // Suara loading dipicu langsung pada tombol tindakan
          },
        );
      },
    );

    final aiState = ref.watch(aiAssistantControllerProvider);
    final isLoading = aiState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Semantics(
          label: 'Tombol Kembali Beranda',
          hint: 'Ketuk dua kali untuk keluar dari asisten visual dan kembali ke layar beranda',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700), size: 32),
            onPressed: () {
              ref.read(hapticServiceProvider).vibrateClick();
              ref.read(ttsServiceProvider).stop();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: const Text(
          'Asisten AI',
          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _buildBody(isLoading, aiState.valueOrNull),
    );
  }

  Widget _buildBody(bool isLoading, dynamic result) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 18),
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Kamera tidak aktif.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    // Menggunakan seluruh sisa area layar sebagai sensor tap-to-capture bagi tunanetra
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            label: 'Sensor Kamera Asisten AI',
            hint: 'Ketuk dua kali di mana saja pada layar ini untuk mengambil foto objek di depan Anda.',
            button: true,
            enabled: !isLoading,
            child: InkWell(
              onTap: isLoading ? null : _takePictureAndAnalyze,
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
        
        // Hamparan memuat data (Loading Overlay) kontras tinggi WCAG 2.2
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(217),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Sedang menganalisis gambar. Harap tunggu...',
                      focused: true,
                      child: const CircularProgressIndicator(
                        color: Color(0xFFFFD700),
                        strokeWidth: 6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sedang Menganalisis...',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Panel Visual Hasil Analisis di bagian bawah (High-Contrast & Large Fonts)
        if (result != null && !isLoading)
          Align(
            alignment: Alignment.bottomCenter,
            child: Semantics(
              label: 'Hasil Analisis Asisten AI',
              container: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: Color(0xFFFFD700), width: 3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Hasil Pemindaian:',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.sceneDescription.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (result.text.toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Teks Terbaca:',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.text.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../help_request/domain/models/help_request_model.dart';
import '../controllers/volunteer_controller.dart';
import 'active_claim_screen.dart';

class VolunteerDashboardScreen extends ConsumerStatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  ConsumerState<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState
    extends ConsumerState<VolunteerDashboardScreen> {
  final Set<String> _knownPendingRequestIds = <String>{};

  bool _hasInitializedPendingRequests = false;
  bool _isNewRequestDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(volunteerDashboardTabControllerProvider);
    final pendingRequestsAsync = ref.watch(pendingHelpRequestsProvider);
    final actionState = ref.watch(volunteerControllerProvider);

    ref.listen<AsyncValue<List<HelpRequestModel>>>(
      pendingHelpRequestsProvider,
      (previous, next) {
        next.whenData(_handlePendingRequestsUpdate);
      },
    );

    ref.listen<AsyncValue<void>>(
      volunteerControllerProvider,
      (previous, next) {
        if (next.hasError) {
          final cleanMessage = next.error.toString().replaceAll('Exception: ', '');
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
        }

        if (previous?.isLoading == true && next.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aksi berhasil dilakukan.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    final user = ref.watch(authControllerProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    final isKtpEnabledAsync = ref.watch(isKtpVerificationEnabledProvider);

    return isKtpEnabledAsync.when(
      data: (isKtpEnabled) {
        if (isKtpEnabled) {
          if (user.verificationStatus == VerificationStatus.pending) {
            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              appBar: AppBar(
                backgroundColor: Colors.black,
                toolbarHeight: 68,
                title: const Text(
                  'Dasbor Relawan',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(authMutationControllerProvider.notifier).signOut();
                    },
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Semantics(
                    label: 'Identitas Anda sedang dalam proses verifikasi oleh tim ITS',
                    focused: true,
                    child: const Text(
                      'Identitas Anda sedang dalam proses verifikasi oleh tim ITS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          if (user.verificationStatus == VerificationStatus.unverified ||
              user.verificationStatus == VerificationStatus.rejected) {
            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              appBar: AppBar(
                backgroundColor: Colors.black,
                toolbarHeight: 68,
                title: const Text(
                  'Verifikasi KTP',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(authMutationControllerProvider.notifier).signOut();
                    },
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              body: KtpVerificationFormView(
                isUploading: actionState.isLoading,
                onUploadKtp: (path) async {
                  ref.read(hapticServiceProvider).vibrateClick();
                  await ref
                      .read(volunteerControllerProvider.notifier)
                      .uploadKtpImage(path);
                },
              ),
            );
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.black,
            toolbarHeight: 68,
            title: Text(
              currentTabIndex == 0 ? 'Dasbor Relawan' : 'Klaim Aktif',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(authMutationControllerProvider.notifier).signOut();
                },
                child: const Text(
                  'Keluar',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: currentTabIndex,
            children: [
              pendingRequestsAsync.when(
                loading: () {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                    ),
                  );
                },
                error: (error, stackTrace) {
                  return _VolunteerDashboardError(
                    message: error.toString(),
                  );
                },
                data: (requests) {
                  if (requests.isEmpty) {
                    return const _EmptyPendingRequestState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(pendingHelpRequestsProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final request = requests[index];

                        return _PendingRequestCard(
                          request: request,
                          isActionLoading: actionState.isLoading,
                          onClaimPressed: () async {
                            ref.read(hapticServiceProvider).vibrateClick();
                            await ref
                                .read(volunteerControllerProvider.notifier)
                                .claimHelpRequest(request.id);
                            final state = ref.read(volunteerControllerProvider);
                            if (!state.hasError) {
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ActiveClaimScreen(),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const _ActiveClaimTabBody(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentTabIndex,
            onTap: (index) {
              ref.read(hapticServiceProvider).vibrateClick();
              ref.read(volunteerDashboardTabControllerProvider.notifier).setTab(index);
            },
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xFFFFD700),
            unselectedItemColor: Colors.white54,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Daftar Bantuan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Klaim Aktif',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  void _handlePendingRequestsUpdate(List<HelpRequestModel> requests) {
    final currentPendingIds = requests.map((request) => request.id).toSet();

    if (!_hasInitializedPendingRequests) {
      _knownPendingRequestIds
        ..clear()
        ..addAll(currentPendingIds);

      _hasInitializedPendingRequests = true;
      return;
    }

    final newRequests = requests.where((request) {
      return !_knownPendingRequestIds.contains(request.id);
    }).toList();

    _knownPendingRequestIds
      ..clear()
      ..addAll(currentPendingIds);

    if (newRequests.isEmpty) {
      return;
    }

    newRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _showNewHelpRequestNotification(newRequests.first);
  }

  void _showNewHelpRequestNotification(HelpRequestModel request) {
    if (_isNewRequestDialogOpen || !mounted) {
      return;
    }

    _isNewRequestDialogOpen = true;

    final requesterName = request.requesterName.trim().isEmpty
        ? 'Pengguna TemanNetra'
        : request.requesterName;

    final description = request.description.trim().isEmpty
        ? 'Pengguna membutuhkan bantuan relawan.'
        : request.description;

    ref.read(hapticServiceProvider).vibrateSuccess();
    ref.read(ttsServiceProvider).speak(
          'Ada pengguna TemanNetra membutuhkan bantuan. '
          'Nama pengguna $requesterName. '
          'Deskripsi bantuan: $description.',
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isNewRequestDialogOpen = false;
        return;
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                color: Color(0xFFFFD700),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Bantuan Baru Masuk',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Semantics(
              focused: true,
              label:
                  'Ada bantuan baru masuk dari $requesterName. Deskripsi bantuan: $description.',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requesterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tiket baru sudah muncul di daftar paling atas.',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Lihat Tiket',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ).then((_) {
        if (mounted) {
          setState(() {
            _isNewRequestDialogOpen = false;
          });
        } else {
          _isNewRequestDialogOpen = false;
        }
      });
    });
  }
}

class _PendingRequestCard extends StatelessWidget {
  final HelpRequestModel request;
  final bool isActionLoading;
  final VoidCallback onClaimPressed;

  const _PendingRequestCard({
    required this.request,
    required this.isActionLoading,
    required this.onClaimPressed,
  });

  @override
  Widget build(BuildContext context) {
    final requesterName = request.requesterName.isEmpty
        ? 'Pengguna TemanNetra'
        : request.requesterName;

    final description = request.description.isEmpty
        ? 'Pengguna membutuhkan bantuan relawan.'
        : request.description;

    return Semantics(
      label: 'Tiket bantuan dari $requesterName. Deskripsi: $description.',
      button: false,
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Color(0xFFFFD700),
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                requesterName,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Dibuat: ${_formatCreatedAt(request.createdAt)}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isActionLoading ? null : onClaimPressed,
                  child: isActionLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Klaim Bantuan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCreatedAt(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _EmptyPendingRequestState extends StatelessWidget {
  const _EmptyPendingRequestState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada tiket bantuan yang menunggu relawan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _VolunteerDashboardError extends StatelessWidget {
  final String message;

  const _VolunteerDashboardError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Gagal memuat tiket bantuan.\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class KtpVerificationFormView extends StatefulWidget {
  final bool isUploading;
  final Future<void> Function(String) onUploadKtp;

  const KtpVerificationFormView({
    super.key,
    required this.isUploading,
    required this.onUploadKtp,
  });

  @override
  State<KtpVerificationFormView> createState() => _KtpVerificationFormViewState();
}

class _KtpVerificationFormViewState extends State<KtpVerificationFormView> {
  CameraController? _cameraController;
  bool _isInitializing = false;
  String _errorMessage = '';
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _errorMessage = '';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'Perangkat tidak memiliki kamera fisik.');
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Gagal mengakses kamera: $e';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    try {
      final file = await controller.takePicture();
      if (mounted) {
        setState(() {
          _capturedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFFD700)),
            SizedBox(height: 16),
            Text(
              'Sedang mengunggah KTP...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_capturedFile != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pratinjau Foto KTP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_capturedFile!.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _capturedFile = null;
                      });
                    },
                    child: const Text('Ambil Ulang'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => widget.onUploadKtp(_capturedFile!.path),
                    child: const Text(
                      'Kirim KTP',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final controller = _cameraController;
    if (_isInitializing || controller == null || !controller.value.isInitialized) {
      return Center(
        child: _errorMessage.isNotEmpty
            ? Text(_errorMessage, style: const TextStyle(color: Colors.redAccent))
            : const CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Silakan posisikan kartu KTP Anda di dalam bingkai kamera, lalu ketuk tombol potret untuk mengunggah verifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _takePicture,
            icon: const Icon(Icons.camera_alt),
            label: const Text(
              'Potret KTP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveClaimTabBody extends ConsumerWidget {
  const _ActiveClaimTabBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimedRequestsState = ref.watch(myClaimedHelpRequestsProvider);
    final actionState = ref.watch(volunteerControllerProvider);

    return claimedRequestsState.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada tiket bantuan yang sedang Anda klaim.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.4,
                ),
              ),
            ),
          );
        }

        final request = requests.first;

        return ActiveClaimSession(
          request: request,
          isActionLoading: actionState.isLoading,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat klaim aktif:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
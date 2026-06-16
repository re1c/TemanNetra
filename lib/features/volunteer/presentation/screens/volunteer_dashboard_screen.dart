import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error.toString()),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (previous?.isLoading == true && next.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aksi berhasil dilakukan.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

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
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ActiveClaimScreen(),
                ),
              );
            },
            child: const Text(
              'Klaim Aktif',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
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
      body: pendingRequestsAsync.when(
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
                  onClaimPressed: () {
                    ref
                        .read(volunteerControllerProvider.notifier)
                        .claimHelpRequest(request.id);
                  },
                );
              },
            ),
          );
        },
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
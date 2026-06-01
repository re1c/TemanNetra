import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannetra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/features/volunteer/presentation/controllers/volunteer_controller.dart';
import 'package:temannetra/features/volunteer/presentation/screens/active_claim_screen.dart';

class VolunteerDashboardScreen extends ConsumerWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequestsAsync = ref.watch(pendingHelpRequestsProvider);
    final actionState = ref.watch(volunteerControllerProvider);

    ref.listen<AsyncValue<void>>(volunteerControllerProvider, (
      previous,
      next,
    ) {
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
            content: Text('Tiket bantuan berhasil diklaim.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Relawan'),
        actions: [
          IconButton(
            tooltip: 'Klaim aktif',
            icon: const Icon(Icons.assignment_turned_in_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ActiveClaimScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: pendingRequestsAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
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
              separatorBuilder: (_, _) => const SizedBox(height: 12),
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
        ? 'Tidak ada deskripsi tambahan.'
        : request.description;

    return Semantics(
      label: 'Tiket bantuan dari $requesterName. Deskripsi: $description.',
      button: false,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requesterName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Dibuat: ${_formatCreatedAt(request.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isActionLoading ? null : onClaimPressed,
                  child: isActionLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Klaim Bantuan'),
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
        ),
      ),
    );
  }
}
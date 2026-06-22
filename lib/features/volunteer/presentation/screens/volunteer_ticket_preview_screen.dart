import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../help_request/domain/models/help_request_model.dart';
import '../controllers/volunteer_controller.dart';
import 'active_claim_screen.dart';

class VolunteerTicketPreviewScreen extends ConsumerStatefulWidget {
  final HelpRequestModel ticket;

  const VolunteerTicketPreviewScreen({
    super.key,
    required this.ticket,
  });

  @override
  ConsumerState<VolunteerTicketPreviewScreen> createState() =>
      _VolunteerTicketPreviewScreenState();
}

class _VolunteerTicketPreviewScreenState
    extends ConsumerState<VolunteerTicketPreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(volunteerControllerProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    ref.listen<AsyncValue<void>>(volunteerControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final cleanMessage = error.toString().replaceAll('Exception: ', '');
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
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 68,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () {
            ref.read(hapticServiceProvider).vibrateClick();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Detail Tiket Bantuan',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('help_requests')
            .doc(widget.ticket.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tiket tidak ditemukan atau sudah dihapus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final ticket = HelpRequestModel.fromMap(data, snapshot.data!.id);

          final requesterName = ticket.requesterName.trim().isEmpty
              ? 'Pengguna TemanNetra'
              : ticket.requesterName;

          final description = ticket.description.trim().isEmpty
              ? 'Pengguna membutuhkan bantuan relawan.'
              : ticket.description;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: Color(0xFFFFD700),
                      width: 1.4,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requesterName,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dibuat: ${_formatCreatedAt(ticket.createdAt)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Deskripsi Kebutuhan:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionArea(ticket, currentUserId, actionState.isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionArea(HelpRequestModel ticket, String? currentUserId, bool isLoading) {
    if (ticket.status == HelpRequestStatus.pending) {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isLoading
              ? null
              : () async {
                  ref.read(hapticServiceProvider).vibrateClick();
                  await ref
                      .read(volunteerControllerProvider.notifier)
                      .claimHelpRequest(ticket.id);
                  final state = ref.read(volunteerControllerProvider);
                  if (!state.hasError && mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActiveClaimScreen(),
                      ),
                    );
                  }
                },
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'Klaim Bantuan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    }

    if (ticket.status == HelpRequestStatus.claimed) {
      final isMine = ticket.volunteerId == currentUserId;
      if (isMine) {
        return Column(
          children: [
            const Text(
              'Anda telah mengklaim bantuan ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF81C784),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF81C784),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.read(hapticServiceProvider).vibrateClick();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const ActiveClaimScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Buka Percakapan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return const Center(
          child: Text(
            'Tiket bantuan ini sudah diklaim oleh relawan lain.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    return const Center(
      child: Text(
        'Bantuan ini sudah selesai.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatCreatedAt(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

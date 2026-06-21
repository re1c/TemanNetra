import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temannetra/features/auth/data/sources/admin_verification_utility.dart';
import 'package:temannetra/features/auth/presentation/controllers/auth_controller.dart';

/// Halaman administratif khusus untuk meninjau dan memproses verifikasi KTP relawan yang tertunda (pending).
class AdminVerificationDashboardScreen extends ConsumerStatefulWidget {
  const AdminVerificationDashboardScreen({super.key});

  @override
  ConsumerState<AdminVerificationDashboardScreen> createState() =>
      _AdminVerificationDashboardScreenState();
}

class _AdminVerificationDashboardScreenState
    extends ConsumerState<AdminVerificationDashboardScreen> {
  final AdminVerificationUtility _adminUtility = AdminVerificationUtility();
  bool _isProcessing = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reviewKtp(String volunteerId, String name) async {
    setState(() => _isProcessing = true);
    try {
      final signedUrl =
          await _adminUtility.generateSecureReviewSession(volunteerId);
      setState(() => _isProcessing = false);

      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          String activeUrl = signedUrl;
          bool isRefreshing = false;

          return StatefulBuilder(
            builder: (context, setBottomSheetState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Tinjau KTP: $name',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.black26,
                            height: 240,
                            child: isRefreshing
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFD700),
                                    ),
                                  )
                                : Image.network(
                                    activeUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFFFD700),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text(
                                          'Gagal memuat gambar KTP',
                                          style: TextStyle(color: Colors.redAccent),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                '* Tautan berlaku selama 300 detik.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: isRefreshing
                                  ? null
                                  : () async {
                                      setBottomSheetState(() {
                                        isRefreshing = true;
                                      });
                                      try {
                                        final newUrl = await _adminUtility
                                            .generateSecureReviewSession(volunteerId);
                                        setBottomSheetState(() {
                                          activeUrl = newUrl;
                                          isRefreshing = false;
                                        });
                                      } catch (e) {
                                        setBottomSheetState(() {
                                          isRefreshing = false;
                                        });
                                        _showError('Gagal menyegarkan token: ${e.toString()}');
                                      }
                                    },
                              icon: const Icon(
                                Icons.refresh,
                                color: Color(0xFFFFD700),
                                size: 16,
                              ),
                              label: const Text(
                                'Muat Ulang',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await _approveVolunteer(volunteerId);
                          },
                          child: const Text(
                            'Setujui Relawan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await _promptRejectionReason(volunteerId);
                          },
                          child: const Text(
                            'Tolak Relawan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Gagal mendapatkan sesi review: ${e.toString()}');
    }
  }

  Future<void> _approveVolunteer(String volunteerId) async {
    setState(() => _isProcessing = true);
    try {
      await _adminUtility.approveVolunteer(volunteerId);
      _showSuccess('Relawan berhasil disetujui.');
    } catch (e) {
      _showError('Gagal menyetujui relawan: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _promptRejectionReason(String volunteerId) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Tolak Pendaftaran',
            style: TextStyle(color: Color(0xFFFFD700)),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFD700)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alasan tidak boleh kosong.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context);
                  await _rejectVolunteer(volunteerId, controller.text.trim());
                }
              },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectVolunteer(String volunteerId, String reason) async {
    setState(() => _isProcessing = true);
    try {
      await _adminUtility.rejectVolunteer(volunteerId, reason);
      _showSuccess('Relawan berhasil ditolak.');
    } catch (e) {
      _showError('Gagal menolak relawan: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 68,
        title: const Text(
          'Panel Verifikasi KTP',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFFD700)),
            onPressed: () {
              ref.read(authMutationControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('system_config')
                    .doc('registration')
                    .snapshots(),
                builder: (context, configSnapshot) {
                  final isKtpEnabled = configSnapshot.data?.data()?['isKtpVerificationEnabled'] as bool? ?? true;
                  return Container(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      activeThumbColor: const Color(0xFFFFD700),
                      activeTrackColor: const Color(0x80FFD700),
                      title: const Text(
                        'Wajibkan Verifikasi KTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Mengaktifkan/menonaktifkan kewajiban upload KTP bagi relawan baru.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: isKtpEnabled,
                      onChanged: (value) async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('system_config')
                              .doc('registration')
                              .set({
                            'isKtpVerificationEnabled': value,
                          }, SetOptions(merge: true));
                          _showSuccess('Verifikasi KTP berhasil di${value ? "aktifkan" : "nonaktifkan"}.');
                        } catch (e) {
                          _showError('Gagal mengubah pengaturan: ${e.toString()}');
                        }
                      },
                    ),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'volunteer')
                      .where('verificationStatus', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Tidak ada permintaan verifikasi pending.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final docId = docs[index].id;
                        final name = data['name'] as String? ?? 'N/A';
                        final email = data['email'] as String? ?? 'N/A';

                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _reviewKtp(docId, name),
                              child: const Text(
                                'Tinjau KTP',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

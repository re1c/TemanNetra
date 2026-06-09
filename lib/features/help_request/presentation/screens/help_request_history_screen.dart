import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../domain/models/help_request_model.dart';
import '../controllers/help_request_controller.dart';
import 'create_help_request_screen.dart';
import 'edit_help_request_screen.dart';
import 'help_request_detail_screen.dart';

/// Layar riwayat daftar tiket bantuan tunanetra (Read & Delete).
///
/// Dioptimalkan penuh untuk akses pembaca layar (TalkBack) dengan representasi
/// data verbal kontras tinggi dan dialog konfirmasi hapus defensif.
class HelpRequestHistoryScreen extends ConsumerStatefulWidget {
  const HelpRequestHistoryScreen({super.key});

  @override
  ConsumerState<HelpRequestHistoryScreen> createState() =>
      _HelpRequestHistoryScreenState();
}

class _HelpRequestHistoryScreenState
    extends ConsumerState<HelpRequestHistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
            'Layar riwayat tiket bantuan Anda aktif. '
            'Menampilkan daftar pengajuan bantuan Anda secara real-time.',
          );
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HelpRequestModel ticket,
  ) async {
    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak(
          'Apakah Anda yakin ingin menghapus tiket bantuan ini secara permanen? '
          'Geser layar untuk memilih opsi Ya atau Batal.',
        );

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Hapus Tiket?',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Ingin menghapus tiket "${ticket.description}"?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            Semantics(
              label: 'Tombol Batal Hapus',
              button: true,
              child: TextButton(
                child: const Text(
                  'BATAL',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  ref.read(hapticServiceProvider).vibrateClick();
                  ref.read(ttsServiceProvider).speak(
                        'Penghapusan dibatalkan.',
                      );
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
            Semantics(
              label: 'Tombol Ya Hapus Permanen',
              button: true,
              child: TextButton(
                child: const Text(
                  'YA, HAPUS',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                  ),
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _executeDelete(ticket.id);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDelete(String id) async {
    ref.read(ttsServiceProvider).speak('Sedang menghapus tiket bantuan...');

    try {
      await ref.read(helpRequestControllerProvider.notifier).deleteTicket(id);
      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak('Tiket bantuan berhasil dihapus.');
    } catch (e) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak(e.toString());
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} pukul '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _mapStatusText(HelpRequestStatus status) {
    switch (status) {
      case HelpRequestStatus.pending:
        return 'Sedang Menunggu Relawan';
      case HelpRequestStatus.claimed:
        return 'Sedang Dibantu Relawan';
      case HelpRequestStatus.resolved:
        return 'Selesai Dibantu';
    }
  }

  Color _mapStatusColor(HelpRequestStatus status) {
    switch (status) {
      case HelpRequestStatus.pending:
        return const Color(0xFFFFD700);
      case HelpRequestStatus.claimed:
        return const Color(0xFF64B5F6);
      case HelpRequestStatus.resolved:
        return const Color(0xFF81C784);
    }
  }

  void _openDetail(HelpRequestModel ticket) {
    ref.read(hapticServiceProvider).vibrateClick();
    ref.read(ttsServiceProvider).speak(
          'Membuka detail tiket bantuan dan pesan koordinasi.',
        );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HelpRequestDetailScreen(ticket: ticket),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(helpRequestControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Semantics(
          label: 'Tombol Kembali Beranda',
          hint: 'Ketuk dua kali untuk kembali ke halaman utama',
          button: true,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFFFFD700),
              size: 32,
            ),
            onPressed: () {
              ref.read(hapticServiceProvider).vibrateClick();
              ref.read(ttsServiceProvider).stop();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: const Text(
          'Daftar Bantuan Saya',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ticketsState.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Semantics(
                  label:
                      'Riwayat tiket kosong. Anda belum memiliki tiket pengajuan bantuan.',
                  focused: true,
                  child: const Text(
                    'Belum Ada Pengajuan Bantuan\n\n'
                    'Ketuk tombol melayang di pojok kanan bawah untuk membuat tiket pertama Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final statusText = _mapStatusText(ticket.status);
              final statusColor = _mapStatusColor(ticket.status);
              final formattedDate = _formatDate(ticket.createdAt);

              final semanticsLabel = 'Kebutuhan bantuan: ${ticket.description}. '
                  'Status tiket: $statusText. '
                  'Dibuat pada tanggal: $formattedDate.';

              return Semantics(
                label: semanticsLabel,
                container: true,
                child: Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: statusColor, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: statusColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  statusText.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ticket.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'Tombol Buka Detail Tiket Bantuan',
                          hint:
                              'Ketuk dua kali untuk melihat pesan koordinasi dari relawan.',
                          button: true,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFFD700),
                                side: const BorderSide(
                                  color: Color(0xFFFFD700),
                                  width: 1.5,
                                ),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text(
                                'BUKA DETAIL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              onPressed: () => _openDetail(ticket),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (ticket.status == HelpRequestStatus.pending)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Semantics(
                                label: 'Tombol Ubah Deskripsi Tiket',
                                hint:
                                    'Ketuk dua kali untuk mengedit kebutuhan tiket bantuan Anda.',
                                button: true,
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFFFFD700),
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(hapticServiceProvider)
                                          .vibrateClick();
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => EditHelpRequestScreen(
                                            helpRequest: ticket,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Semantics(
                                label: 'Tombol Hapus Tiket Bantuan',
                                hint:
                                    'Ketuk dua kali untuk menghapus pengajuan tiket bantuan ini secara permanen.',
                                button: true,
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, ticket),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: Semantics(
            label: 'Sedang memuat data riwayat tiket bantuan Anda.',
            focused: true,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD700),
              ),
            ),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              label: 'Gagal memuat riwayat bantuan: $err',
              focused: true,
              child: Text(
                'Terjadi Kesalahan:\n$err',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Tombol Buat Tiket Bantuan Baru',
        hint: 'Ketuk dua kali untuk masuk ke formulir pengajuan bantuan relawan.',
        button: true,
        child: SizedBox(
          width: 72,
          height: 72,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            onPressed: () {
              ref.read(hapticServiceProvider).vibrateClick();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateHelpRequestScreen(),
                ),
              );
            },
            child: const Icon(Icons.add, size: 36),
          ),
        ),
      ),
    );
  }
}
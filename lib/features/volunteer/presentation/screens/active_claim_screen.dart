import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/core/models/chat_message_model.dart';
import 'package:temannetra/features/volunteer/presentation/controllers/volunteer_controller.dart';
import 'package:temannetra/features/volunteer/presentation/widgets/audio_message_player.dart';
import 'package:temannetra/core/widgets/voice_note_button.dart';

class ActiveClaimScreen extends ConsumerWidget {
  const ActiveClaimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimedRequestsState = ref.watch(myClaimedHelpRequestsProvider);
    final actionState = ref.watch(volunteerControllerProvider);

    ref.listen<AsyncValue<void>>(volunteerControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous?.isLoading == true) {
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
        leadingWidth: 96,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Kembali',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: const Text(
          'Klaim Aktif',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
      ),
      body: claimedRequestsState.when(
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
                    fontSize: 20,
                    height: 1.4,
                  ),
                ),
              ),
            );
          }

          final request = requests.first;

          return _ActiveClaimSession(
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
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveClaimSession extends ConsumerStatefulWidget {
  final HelpRequestModel request;
  final bool isActionLoading;

  const _ActiveClaimSession({
    required this.request,
    required this.isActionLoading,
  });

  @override
  ConsumerState<_ActiveClaimSession> createState() =>
      _ActiveClaimSessionState();
}

class _ActiveClaimSessionState extends ConsumerState<_ActiveClaimSession> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} pukul '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendTextMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan tidak boleh kosong.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(volunteerControllerProvider.notifier).sendTextMessage(
          requestId: widget.request.id,
          messageText: message,
        );

    final actionState = ref.read(volunteerControllerProvider);
    if (!actionState.hasError) {
      _messageController.clear();
    }
  }

  Future<void> _sendVoiceMessage(String voicePath) async {
    await ref.read(volunteerControllerProvider.notifier).sendVoiceMessage(
          requestId: widget.request.id,
          voicePath: voicePath,
        );
  }

  Future<void> _resolveRequest() async {
    await ref.read(volunteerControllerProvider.notifier).resolveHelpRequest(
          widget.request.id,
        );
  }

  Future<void> _cancelClaim() async {
    await ref.read(volunteerControllerProvider.notifier).cancelClaim(
          widget.request.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final requesterName = widget.request.requesterName.trim().isEmpty
        ? 'Pengguna TemanNetra'
        : widget.request.requesterName;

    final chatState = ref.watch(chatMessagesProvider(widget.request.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: _TicketHeaderCard(
            name: requesterName,
            date: _formatDate(widget.request.createdAt),
            description: widget.request.description,
            volunteerName: widget.request.volunteerName,
            isLoading: widget.isActionLoading,
            onResolve: _resolveRequest,
            onCancel: _cancelClaim,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Percakapan',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: chatState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Belum ada pesan koordinasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final message = messages[index];

                    return _MessageBubble(
                      message: message,
                      isMine: message.senderId == currentUser?.uid,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFD700),
                  ),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Gagal memuat pesan:\n$error',
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
        ),
        Container(
          color: const Color(0xFF2C2416),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x80FFD700)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFFD700)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Perhatian Relawan: Berikan informasi dengan akurasi tinggi. Dilarang memberikan diagnosis medis atau hukum kepada pengguna.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        _MessageComposer(
          controller: _messageController,
          isLoading: widget.isActionLoading,
          onSendText: _sendTextMessage,
          onSendVoice: _sendVoiceMessage,
        ),
      ],
    );
  }
}

class _TicketHeaderCard extends StatelessWidget {
  final String name;
  final String date;
  final String description;
  final String? volunteerName;
  final bool isLoading;
  final VoidCallback onResolve;
  final VoidCallback onCancel;

  const _TicketHeaderCard({
    required this.name,
    required this.date,
    required this.description,
    required this.volunteerName,
    required this.isLoading,
    required this.onResolve,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: Color(0xFFFFD700),
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                height: 1.3,
              ),
            ),
            if (volunteerName != null) ...[
              const SizedBox(height: 10),
              Text(
                'Relawan: $volunteerName',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading ? null : onResolve,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF81C784),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSendText;
  final Future<void> Function(String voicePath) onSendVoice;

  const _MessageComposer({
    required this.controller,
    required this.isLoading,
    required this.onSendText,
    required this.onSendVoice,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VoiceNoteButton(
              isDisabled: isLoading,
              fullWidth: true,
              onVoiceReady: onSendVoice,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isLoading,
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan teks',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF181818),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white54),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 54,
                  width: 88,
                  child: FilledButton(
                    onPressed: isLoading ? null : onSendText,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Kirim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final messageText = message.messageText?.trim();
    final messageUrl = message.messageUrl?.trim();
    final hasAudio = messageUrl != null && messageUrl.isNotEmpty;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isMine ? const Color(0xFF2C2600) : const Color(0xFF242424),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMine ? const Color(0xFFFFD700) : Colors.white24,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.senderName.isEmpty
                    ? 'Pengguna TemanNetra'
                    : message.senderName,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (hasAudio)
                AudioMessagePlayer(audioUrl: messageUrl)
              else
                Text(
                  messageText == null || messageText.isEmpty
                      ? 'Pesan kosong'
                      : messageText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _formatDate(message.createdAt),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/features/volunteer/domain/models/chat_message_model.dart';
import 'package:temannetra/features/volunteer/presentation/controllers/volunteer_controller.dart';
import 'package:temannetra/features/volunteer/presentation/widgets/audio_message_player.dart';
import 'package:temannetra/features/volunteer/presentation/widgets/voice_note_button.dart';

class ActiveClaimScreen extends ConsumerWidget {
  const ActiveClaimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimedRequestsState = ref.watch(myClaimedHelpRequestsProvider);
    final actionState = ref.watch(volunteerControllerProvider);

    ref.listen(volunteerControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aksi berhasil dilakukan.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
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
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        title: const Text(
          'Klaim Aktif',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
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
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _ClaimedRequestCard(
                request: requests[index],
                isActionLoading: actionState.isLoading,
              );
            },
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimedRequestCard extends ConsumerStatefulWidget {
  final HelpRequestModel request;
  final bool isActionLoading;

  const _ClaimedRequestCard({
    required this.request,
    required this.isActionLoading,
  });

  @override
  ConsumerState<_ClaimedRequestCard> createState() =>
      _ClaimedRequestCardState();
}

class _ClaimedRequestCardState extends ConsumerState<_ClaimedRequestCard> {
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

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label:
                  'Tiket bantuan aktif dari $requesterName. Deskripsi bantuan: ${widget.request.description}.',
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requesterName,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(widget.request.createdAt),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.request.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                  if (widget.request.volunteerName != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Relawan: ${widget.request.volunteerName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        widget.isActionLoading ? null : _resolveRequest,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF81C784),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Selesai',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.isActionLoading ? null : _cancelClaim,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Percakapan',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: chatState.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Belum ada pesan koordinasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Gagal memuat pesan:\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!widget.isActionLoading) {
                        _sendTextMessage();
                      }
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tulis pesan koordinasi',
                      labelStyle: TextStyle(color: Color(0xFFFFD700)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                VoiceNoteButton(
                  isDisabled: widget.isActionLoading,
                  onVoiceReady: _sendVoiceMessage,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 52,
                  child: FilledButton(
                    onPressed:
                        widget.isActionLoading ? null : _sendTextMessage,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                    ),
                    child: widget.isActionLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.send),
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
        constraints: const BoxConstraints(maxWidth: 290),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine ? const Color(0xFF2C2600) : const Color(0xFF242424),
            borderRadius: BorderRadius.circular(12),
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
                  fontSize: 13,
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
                    fontSize: 15,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _formatDate(message.createdAt),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
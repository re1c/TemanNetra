import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/chat_message_model.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../../../core/widgets/voice_note_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../volunteer/presentation/widgets/audio_message_player.dart';
import '../../domain/models/help_request_model.dart';
import '../controllers/help_request_controller.dart';

class HelpRequestDetailScreen extends ConsumerStatefulWidget {
  final HelpRequestModel ticket;

  const HelpRequestDetailScreen({
    super.key,
    required this.ticket,
  });

  @override
  ConsumerState<HelpRequestDetailScreen> createState() =>
      _HelpRequestDetailScreenState();
}

class _HelpRequestDetailScreenState
    extends ConsumerState<HelpRequestDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final Set<String> _autoPlayedAudioMessageIds = <String>{};

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
            'Detail bantuan dibuka. Anda dapat membaca dan mengirim pesan koordinasi di halaman ini.',
          );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String? _findAutoPlayableIncomingVoiceNoteId(
    List<ChatMessageModel> messages,
    String? currentUserId,
  ) {
    if (currentUserId == null) {
      return null;
    }

    for (final message in messages.reversed) {
      final audioUrl = message.messageUrl?.trim();
      final hasAudio = audioUrl != null && audioUrl.isNotEmpty;
      final isIncoming = message.senderId != currentUserId;
      final hasNotBeenPlayed = !_autoPlayedAudioMessageIds.contains(message.id);

      if (hasAudio && isIncoming && hasNotBeenPlayed) {
        return message.id;
      }
    }

    return null;
  }

  Future<void> _sendTextMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak('Pesan tidak boleh kosong.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await ref.read(helpRequestControllerProvider.notifier).sendTextMessage(
            requestId: widget.ticket.id,
            messageText: message,
          );

      _messageController.clear();

      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak('Pesan berhasil dikirim.');
    } catch (e) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak('Gagal mengirim pesan.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendVoiceMessage(String voicePath) async {
    setState(() {
      _isSending = true;
    });

    try {
      await ref.read(helpRequestControllerProvider.notifier).sendVoiceMessage(
            requestId: widget.ticket.id,
            voicePath: voicePath,
          );

      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak('Voice note berhasil dikirim.');
    } catch (e) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak('Gagal mengirim voice note.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim voice note: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
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
        return 'Menunggu Relawan';
      case HelpRequestStatus.claimed:
        return 'Sedang Dibantu';
      case HelpRequestStatus.resolved:
        return 'Selesai';
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

  @override
  Widget build(BuildContext context) {
    final statusText = _mapStatusText(widget.ticket.status);
    final statusColor = _mapStatusColor(widget.ticket.status);
    final canSendMessage = widget.ticket.status == HelpRequestStatus.claimed;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 64,
        leadingWidth: 96,
        leading: TextButton(
          onPressed: () {
            ref.read(hapticServiceProvider).vibrateClick();
            ref.read(ttsServiceProvider).stop();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Kembali',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: const Text(
          'Detail Bantuan',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: _TicketSummaryCard(
              date: _formatDate(widget.ticket.createdAt),
              description: widget.ticket.description,
              statusText: statusText,
              statusColor: statusColor,
              volunteerName: widget.ticket.volunteerName,
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
              child: ref.watch(helpRequestMessagesProvider(widget.ticket.id)).when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD700),
                        ),
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Gagal memuat pesan:\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    data: (messages) {
                      final currentUserId = ref.read(authControllerProvider).valueOrNull?.uid;
                      final autoPlayMessageId = _findAutoPlayableIncomingVoiceNoteId(
                        messages,
                        currentUserId,
                      );

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
                          final message = messages[index];
                          final isMine = message.senderId == currentUserId;
                          final shouldAutoPlay = message.id == autoPlayMessageId;

                          return _MessageBubble(
                            message: message,
                            isMine: isMine,
                            autoPlay: shouldAutoPlay,
                            onAutoPlayStarted: () {
                              _autoPlayedAudioMessageIds.add(message.id);
                            },
                          );
                        },
                      );
                    },
                  ),
            ),
          ),
          if (canSendMessage)
            _MessageComposer(
              controller: _messageController,
              isLoading: _isSending,
              onSendText: _sendTextMessage,
              onSendVoice: _sendVoiceMessage,
            )
          else
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Text(
                  widget.ticket.status == HelpRequestStatus.pending
                      ? 'Pesan dapat dikirim setelah relawan menerima bantuan Anda.'
                      : 'Bantuan sudah selesai. Percakapan tidak dapat dilanjutkan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TicketSummaryCard extends StatelessWidget {
  final String date;
  final String description;
  final String statusText;
  final Color statusColor;
  final String? volunteerName;

  const _TicketSummaryCard({
    required this.date,
    required this.description,
    required this.statusText,
    required this.statusColor,
    required this.volunteerName,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Detail bantuan. Deskripsi: $description. Status: $statusText. Relawan: ${volunteerName ?? "belum ada relawan"}.',
      container: true,
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: statusColor,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (volunteerName != null)
                    Text(
                      'Relawan: $volunteerName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ],
          ),
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
              height: 72,
              fontSize: 21,
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
  final bool autoPlay;
  final VoidCallback? onAutoPlayStarted;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.autoPlay,
    this.onAutoPlayStarted,
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

    return Semantics(
      label: hasAudio
          ? 'Voice note dari ${message.senderName}.'
          : 'Pesan dari ${message.senderName}. Isi pesan: ${messageText ?? "Pesan kosong"}.',
      container: true,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isMine ? const Color(0xFF2C2600) : const Color(0xFF242424),
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
                  AudioMessagePlayer(
                    audioUrl: messageUrl,
                    autoPlay: autoPlay,
                    onAutoPlayStarted: onAutoPlayStarted,
                  )
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
      ),
    );
  }
}
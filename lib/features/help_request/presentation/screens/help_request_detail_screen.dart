import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../../volunteer/data/services/voice_note_storage_service.dart';
import '../../../volunteer/domain/models/chat_message_model.dart';
import '../../../volunteer/presentation/widgets/audio_message_player.dart';
import '../../../volunteer/presentation/widgets/voice_note_button.dart';
import '../../domain/models/help_request_model.dart';

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
  final VoiceNoteStorageService _voiceNoteStorageService =
      VoiceNoteStorageService();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
            'Detail tiket bantuan dibuka. '
            'Anda dapat membaca pesan koordinasi dari relawan di halaman ini.',
          );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Stream<List<ChatMessageModel>> _watchMessages() {
    return FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.ticket.id)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<String> _getCurrentUserName(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return userDoc.data()?['name'] as String? ?? 'Pengguna TemanNetra';
  }

  Future<void> _sendTextMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak('Pesan tidak boleh kosong.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak(
            'Sesi pengguna tidak valid. Silakan masuk kembali.',
          );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final senderName = await _getCurrentUserName(currentUser.uid);

      final messageDoc = FirebaseFirestore.instance
          .collection('help_requests')
          .doc(widget.ticket.id)
          .collection('messages')
          .doc();

      await messageDoc.set({
        'id': messageDoc.id,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'messageText': message,
        'messageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak(
            'Sesi pengguna tidak valid. Silakan masuk kembali.',
          );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final senderName = await _getCurrentUserName(currentUser.uid);

      final voiceUrl = await _voiceNoteStorageService.uploadVoiceNote(
        requestId: widget.ticket.id,
        localFilePath: voicePath,
      );

      final messageDoc = FirebaseFirestore.instance
          .collection('help_requests')
          .doc(widget.ticket.id)
          .collection('messages')
          .doc();

      await messageDoc.set({
        'id': messageDoc.id,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'messageText': null,
        'messageUrl': voiceUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

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

  @override
  Widget build(BuildContext context) {
    final statusText = _mapStatusText(widget.ticket.status);
    final statusColor = _mapStatusColor(widget.ticket.status);
    final canSendMessage = widget.ticket.status == HelpRequestStatus.claimed;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Semantics(
          label: 'Tombol kembali ke daftar bantuan saya',
          hint: 'Ketuk dua kali untuk kembali ke halaman sebelumnya.',
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
          'Detail Bantuan',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label:
                  'Detail tiket bantuan. Kebutuhan bantuan: ${widget.ticket.description}. '
                  'Status tiket: $statusText.',
              container: true,
              child: Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: statusColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _formatDate(widget.ticket.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.ticket.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.ticket.volunteerName != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Relawan: ${widget.ticket.volunteerName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Percakapan',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _watchMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD700),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat pesan:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada pesan koordinasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isMine = message.senderId == currentUser?.uid;

                    return _MessageCard(
                      message: message,
                      isMine: isMine,
                    );
                  },
                );
              },
            ),
          ),
          if (canSendMessage)
            _MessageInputBar(
              controller: _messageController,
              isSending: _isSending,
              onSendText: _sendTextMessage,
              onSendVoice: _sendVoiceMessage,
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.ticket.status == HelpRequestStatus.pending
                    ? 'Pesan dapat dikirim setelah tiket diklaim oleh relawan.'
                    : 'Tiket sudah selesai. Percakapan tidak dapat dilanjutkan.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _MessageCard({
    required this.message,
    required this.isMine,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} pukul '
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
          ? 'Voice note dari ${message.senderName}. Dikirim pada ${_formatDate(message.createdAt)}.'
          : 'Pesan dari ${message.senderName}. Isi pesan: ${messageText ?? 'Pesan kosong'}. Dikirim pada ${_formatDate(message.createdAt)}.',
      container: true,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Card(
            color: isMine ? const Color(0xFF2C2600) : const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isMine ? const Color(0xFFFFD700) : Colors.white24,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSendText;
  final Future<void> Function(String voicePath) onSendVoice;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSendText,
    required this.onSendVoice,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Semantics(
                label: 'Kolom untuk menulis pesan balasan kepada relawan',
                textField: true,
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!isSending) {
                      onSendText();
                    }
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tulis pesan',
                    labelStyle: TextStyle(color: Color(0xFFFFD700)),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            VoiceNoteButton(
              isDisabled: isSending,
              onVoiceReady: onSendVoice,
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Tombol kirim pesan',
              hint: 'Ketuk dua kali untuk mengirim pesan ke relawan.',
              button: true,
              child: SizedBox(
                width: 52,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: isSending ? null : onSendText,
                  child: isSending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.send, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
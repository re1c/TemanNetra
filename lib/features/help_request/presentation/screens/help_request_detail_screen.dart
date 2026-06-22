import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temannetra/l10n/app_localizations.dart';
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
  bool _hasSpokenPendingAnnouncement = false;
  bool _hasSpokenSecurityWarning = false;
  bool _isSendingImage = false;
  bool _hasShownSecurityWarningDialog = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.ticket.status == HelpRequestStatus.claimed) {
        _hasSpokenSecurityWarning = true;
        final warningMsg = AppLocalizations.of(context)?.securityWarningAnnouncement ??
            'Peringatan Keamanan: Jangan pernah menyebutkan kata sandi atau informasi keuangan Anda.';
        ref.read(ttsServiceProvider).speak(
              'Detail bantuan dibuka. Relawan telah terhubung. $warningMsg',
            );
        _showSecurityWarningDialog();
      } else if (widget.ticket.status != HelpRequestStatus.pending) {
        ref.read(ttsServiceProvider).speak(
              'Detail bantuan dibuka. Anda dapat membaca dan mengirim pesan koordinasi di halaman ini.',
            );
      }
    });
  }

  void _showSecurityWarningDialog() {
    if (_hasShownSecurityWarningDialog || !mounted) return;
    _hasShownSecurityWarningDialog = true;

    final warningMsg = AppLocalizations.of(context)?.securityWarningAnnouncement ??
        'Jangan pernah menyebutkan kata sandi atau informasi keuangan Anda.';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 10),
              Text(
                'Peringatan Keamanan',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            warningMsg,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.read(hapticServiceProvider).vibrateClick();
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Saya Mengerti',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
      final hasNotBeenPlayed = !_autoPlayedAudioMessageIds.contains(message.id) && !message.isPlayed;

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

    await ref.read(helpRequestControllerProvider.notifier).sendTextMessage(
          requestId: widget.ticket.id,
          messageText: message,
        );

    final actionState = ref.read(helpRequestControllerProvider);
    if (!actionState.hasError) {
      _messageController.clear();
      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak('Pesan berhasil dikirim.');
    }
  }

  Future<void> _sendVoiceMessage(String voicePath) async {
    await ref.read(helpRequestControllerProvider.notifier).sendVoiceMessage(
          requestId: widget.ticket.id,
          voicePath: voicePath,
        );

    final actionState = ref.read(helpRequestControllerProvider);
    if (!actionState.hasError) {
      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak('Voice note berhasil dikirim.');
    }
  }

  Future<void> _takeAndSendPhoto() async {
    ref.read(hapticServiceProvider).vibrateClick();
    final file = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) => const CameraCaptureScreen(),
      ),
    );
    if (file != null) {
      await _sendImageMessage(file);
    }
  }

  Future<void> _sendImageMessage(XFile file) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() {
      _isSendingImage = true;
    });

    try {
      final bytes = await File(file.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Gagal mendecode gambar.');
      }

      img.Image resizedImage = decoded;
      if (decoded.width > 1024 || decoded.height > 1024) {
        if (decoded.width > decoded.height) {
          resizedImage = img.copyResize(decoded, width: 1024);
        } else {
          resizedImage = img.copyResize(decoded, height: 1024);
        }
      }

      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);
      final compressedFile = File(file.path);
      await compressedFile.writeAsBytes(compressedBytes);

      final String secureFileName = '${widget.ticket.id}_CHAT_IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final client = Supabase.instance.client;
      await client.storage.from('chat_attachments').upload(
            secureFileName,
            compressedFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final imageUrl = client.storage.from('chat_attachments').getPublicUrl(secureFileName).toString();

      final senderName = currentUser.name.isEmpty ? 'Pengguna TemanNetra' : currentUser.name;
      final messageDocRef = FirebaseFirestore.instance
          .collection('help_requests')
          .doc(widget.ticket.id)
          .collection('messages')
          .doc();

      await messageDocRef.set({
        'id': messageDocRef.id,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'messageText': null,
        'messageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'messageType': 'image',
        'isPlayed': false,
        'duration': null,
      });

      ref.read(hapticServiceProvider).vibrateSuccess();
      ref.read(ttsServiceProvider).speak('Foto berhasil dikirim.');
    } catch (e) {
      ref.read(hapticServiceProvider).vibrateError();
      ref.read(ttsServiceProvider).speak('Gagal mengirim foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim foto: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      try {
        final f = File(file.path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSendingImage = false;
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} pukul '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _mapStatusText(BuildContext context, HelpRequestStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case HelpRequestStatus.pending:
        return l10n?.ticketStatusPending ?? 'Menunggu Relawan';
      case HelpRequestStatus.claimed:
        return l10n?.ticketStatusClaimed ?? 'Sedang Dibantu';
      case HelpRequestStatus.resolved:
        return l10n?.ticketStatusResolved ?? 'Selesai';
      case HelpRequestStatus.cancelled:
        return 'Dibatalkan';
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
      case HelpRequestStatus.cancelled:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen<AsyncValue<void>>(
      helpRequestControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, _) {
            final errorMessage = error.toString().replaceFirst('Exception: ', '');
            ref.read(hapticServiceProvider).vibrateError();
            ref.read(ttsServiceProvider).speak(errorMessage);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.red[800],
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );

    ref.listen<AsyncValue<List<HelpRequestModel>>>(
      myHelpRequestsProvider,
      (previous, next) {
        final prevList = previous?.valueOrNull;
        final nextList = next.valueOrNull;
        if (nextList == null) return;

        final ticketExists = nextList.any((t) => t.id == widget.ticket.id);
        if (!ticketExists) {
          if (Navigator.of(context).canPop()) {
            ref.invalidate(helpRequestMessagesProvider(widget.ticket.id));
            ref.invalidate(myHelpRequestsProvider);
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          return;
        }

        if (prevList == null) return;

        final prevTicket = prevList.firstWhere(
          (t) => t.id == widget.ticket.id,
          orElse: () => widget.ticket,
        );
        final nextTicket = nextList.firstWhere(
          (t) => t.id == widget.ticket.id,
          orElse: () => widget.ticket,
        );

        if (prevTicket.status == HelpRequestStatus.claimed) {
          if (nextTicket.status == HelpRequestStatus.resolved ||
              nextTicket.status == HelpRequestStatus.pending) {
            if (Navigator.of(context).canPop()) {
              ref.invalidate(helpRequestMessagesProvider(widget.ticket.id));
              ref.invalidate(myHelpRequestsProvider);
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }
        }
      },
    );

    ref.listen<AsyncValue<List<ChatMessageModel>>>(
      helpRequestMessagesProvider(widget.ticket.id),
      (previous, next) {
        final currentUserId = ref.read(authControllerProvider).valueOrNull?.uid;
        next.whenData((messages) {
          if (messages.isEmpty) return;

          final latestMessage = messages.last;
          if (latestMessage.senderId != currentUserId) {
            final previousList = previous?.valueOrNull;
            final isNew = previousList != null && !previousList.any((m) => m.id == latestMessage.id);
            if (isNew) {
              if (latestMessage.messageType == 'text' && latestMessage.messageText != null && latestMessage.messageText!.isNotEmpty) {
                ref.read(ttsServiceProvider).speak(
                  'Pesan baru dari ${latestMessage.senderName}: ${latestMessage.messageText}',
                );
              } else if (latestMessage.messageType == 'audio' && latestMessage.messageUrl != null && latestMessage.messageUrl!.isNotEmpty) {
                ref.read(ttsServiceProvider).speak(
                  'Pesan suara baru diterima dari ${latestMessage.senderName}.',
                );
              } else if (latestMessage.messageType == 'image') {
                ref.read(ttsServiceProvider).speak(
                  'Foto baru diterima dari ${latestMessage.senderName}.',
                );
              }
            }
          }
        });
      },
    );

    final myRequests = ref.watch(myHelpRequestsProvider).valueOrNull;
    final currentTicket = myRequests?.firstWhere(
          (t) => t.id == widget.ticket.id,
          orElse: () => widget.ticket,
        ) ??
        widget.ticket;

    if (!_hasSpokenPendingAnnouncement && currentTicket.status == HelpRequestStatus.pending) {
      _hasSpokenPendingAnnouncement = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ttsServiceProvider).speak(
              l10n?.volunteerWaitingAnnouncement ??
                  'Permintaan bantuan berhasil dikirim. Sedang mencari relawan terdekat. Mohon tunggu, Anda dapat mengirim pesan setelah relawan terhubung.',
            );
      });
    }

    if (!_hasSpokenSecurityWarning && currentTicket.status == HelpRequestStatus.claimed) {
      _hasSpokenSecurityWarning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final warningMsg = AppLocalizations.of(context)?.securityWarningAnnouncement ??
            'Peringatan Keamanan: Jangan pernah menyebutkan kata sandi atau informasi keuangan Anda.';
        ref.read(ttsServiceProvider).speak(
              'Relawan terhubung. $warningMsg',
            );
        _showSecurityWarningDialog();
      });
    }

    final statusText = _mapStatusText(context, currentTicket.status);
    final statusColor = _mapStatusColor(currentTicket.status);
    final canSendMessage = currentTicket.status == HelpRequestStatus.claimed;

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
            ref.invalidate(helpRequestMessagesProvider(widget.ticket.id));
            ref.invalidate(myHelpRequestsProvider);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text(
            l10n?.backButtonLabel ?? 'Kembali',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          l10n?.helpRequestDetailsTitle ?? 'Detail Bantuan',
          style: const TextStyle(
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
              date: _formatDate(currentTicket.createdAt),
              description: currentTicket.description,
              statusText: statusText,
              statusColor: statusColor,
              volunteerName: currentTicket.volunteerName,
            ),
          ),
          if (currentTicket.status == HelpRequestStatus.claimed)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Semantics(
                label: 'Tombol Selesaikan Bantuan',
                hint: 'Ketuk dua kali untuk menyelesaikan sesi bantuan ini.',
                button: true,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF81C784),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: ref.watch(helpRequestControllerProvider).isLoading
                      ? null
                      : () async {
                          ref.read(hapticServiceProvider).vibrateClick();
                          ref.read(ttsServiceProvider).speak('Sedang menyelesaikan bantuan...');
                          ref.invalidate(helpRequestMessagesProvider(currentTicket.id));
                          ref.invalidate(myHelpRequestsProvider);
                          await ref
                              .read(helpRequestControllerProvider.notifier)
                              .resolveHelpRequest(currentTicket.id);
                          final state = ref.read(helpRequestControllerProvider);
                          if (!state.hasError) {
                            ref.read(hapticServiceProvider).vibrateSuccess();
                            ref.read(ttsServiceProvider).speak('Bantuan telah diselesaikan.');
                            if (context.mounted) {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          }
                        },
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
              child: ref.watch(helpRequestMessagesProvider(currentTicket.id)).when(
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

                      final reversedMessages = messages.reversed.toList();
                      return ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(14),
                        itemCount: reversedMessages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final message = reversedMessages[index];
                          final isMine = message.senderId == currentUserId;
                          final shouldAutoPlay = message.id == autoPlayMessageId;

                          return _MessageBubble(
                            message: message,
                            isMine: isMine,
                            autoPlay: shouldAutoPlay,
                            onAutoPlayStarted: () {
                              _autoPlayedAudioMessageIds.add(message.id);
                              FirebaseFirestore.instance
                                  .collection('help_requests')
                                  .doc(currentTicket.id)
                                  .collection('messages')
                                  .doc(message.id)
                                  .update({'isPlayed': true}).catchError((_) {});
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
              isLoading: ref.watch(helpRequestControllerProvider).isLoading || _isSendingImage,
              onSendText: _sendTextMessage,
              onSendVoice: _sendVoiceMessage,
              onSendPhoto: _takeAndSendPhoto,
            )
          else
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: currentTicket.status == HelpRequestStatus.pending
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pesan dapat dikirim setelah relawan menerima bantuan Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Tombol Batalkan Permintaan',
                            hint: 'Ketuk dua kali untuk membatalkan permintaan bantuan ini.',
                            button: true,
                            child: SizedBox(
                              height: 64,
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: ref.watch(helpRequestControllerProvider).isLoading
                                    ? null
                                    : () async {
                                        ref.read(hapticServiceProvider).vibrateClick();
                                        ref.read(ttsServiceProvider).speak('Sedang membatalkan permintaan...');
                                        ref.invalidate(helpRequestMessagesProvider(currentTicket.id));
                                        ref.invalidate(myHelpRequestsProvider);
                                        await ref
                                            .read(helpRequestControllerProvider.notifier)
                                            .cancelHelpRequest(currentTicket.id);
                                        final state = ref.read(helpRequestControllerProvider);
                                        if (!state.hasError) {
                                          ref.read(hapticServiceProvider).vibrateSuccess();
                                          ref.read(ttsServiceProvider).speak('Permintaan telah dibatalkan.');
                                          if (context.mounted) {
                                            Navigator.of(context).popUntil((route) => route.isFirst);
                                          }
                                        }
                                      },
                                child: const Text(
                                  'Batalkan Permintaan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Bantuan sudah selesai. Percakapan tidak dapat dilanjutkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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

class _MessageComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSendText;
  final Future<void> Function(String voicePath) onSendVoice;
  final VoidCallback onSendPhoto;

  const _MessageComposer({
    required this.controller,
    required this.isLoading,
    required this.onSendText,
    required this.onSendVoice,
    required this.onSendPhoto,
  });

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Visibility(
              visible: !_isRecording,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  label: 'Tombol Kirim Foto. Ketuk dua kali untuk membuka kamera dan mengambil foto.',
                  button: true,
                  child: SizedBox(
                    height: 64,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: widget.isLoading ? null : widget.onSendPhoto,
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text(
                        'Kirim Foto',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _isRecording ? 72 : 64,
              child: VoiceNoteButton(
                key: const ValueKey('tunanetra_voice_note_button'),
                isDisabled: widget.isLoading,
                isCompact: false,
                height: _isRecording ? 72 : 64,
                fontSize: 20,
                label: 'Mulai Rekam Suara',
                icon: Icons.mic,
                onVoiceReady: widget.onSendVoice,
                onRecordingChanged: (recording) {
                  setState(() {
                    _isRecording = recording;
                  });
                },
              ),
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
    final isAudio = message.messageType == 'audio';
    final isImage = message.messageType == 'image';

    return Semantics(
      label: isImage
          ? 'Kiriman foto dari ${message.senderName}.'
          : isAudio
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
                if (isAudio && messageUrl != null && messageUrl.isNotEmpty)
                  AudioMessagePlayer(
                    audioUrl: messageUrl,
                    autoPlay: autoPlay,
                    onAutoPlayStarted: onAutoPlayStarted,
                  )
                else if (isImage && messageUrl != null && messageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      messageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: double.infinity,
                          color: const Color(0xFF1E1E1E),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.redAccent, size: 36),
                              SizedBox(height: 8),
                              Text(
                                '[Gambar gagal dimuat]',
                                style: TextStyle(color: Colors.redAccent, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _cameraController;
  bool _isInitializing = false;
  String _errorMessage = '';

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
        Navigator.of(context).pop(file);
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
    final controller = _cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Ambil Foto',
          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isInitializing || controller == null || !controller.value.isInitialized
          ? Center(
              child: _errorMessage.isNotEmpty
                  ? Text(_errorMessage, style: const TextStyle(color: Colors.redAccent))
                  : const CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: CameraPreview(controller),
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
                      'Ambil Foto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
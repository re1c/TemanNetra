import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/features/volunteer/domain/models/chat_message_model.dart';
import 'package:temannetra/features/volunteer/presentation/controllers/volunteer_controller.dart';

class ActiveClaimScreen extends ConsumerWidget {
  const ActiveClaimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimedRequestsAsync = ref.watch(myClaimedHelpRequestsProvider);
    final volunteerState = ref.watch(volunteerControllerProvider);

    ref.listen<AsyncValue<void>>(volunteerControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        data: (_) {
          final wasLoading = previous?.isLoading ?? false;
          if (wasLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aksi relawan berhasil diproses.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klaim Aktif'),
      ),
      body: claimedRequestsAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, _) {
          return _ActiveClaimError(
            message: error.toString(),
          );
        },
        data: (requests) {
          if (requests.isEmpty) {
            return const _EmptyActiveClaimState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myClaimedHelpRequestsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];

                return _ClaimedRequestCard(
                  request: request,
                  isLoading: volunteerState.isLoading,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ClaimedRequestCard extends ConsumerStatefulWidget {
  final HelpRequestModel request;
  final bool isLoading;

  const _ClaimedRequestCard({
    required this.request,
    required this.isLoading,
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    await ref.read(volunteerControllerProvider.notifier).sendTextMessage(
          requestId: widget.request.id,
          messageText: message,
        );

    final actionState = ref.read(volunteerControllerProvider);
    if (mounted && !actionState.hasError) {
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.request.id));

    final requesterName = widget.request.requesterName.isEmpty
        ? 'Pengguna TemanNetra'
        : widget.request.requesterName;

    final description = widget.request.description.isEmpty
        ? 'Tidak ada deskripsi tambahan.'
        : widget.request.description;

    return Semantics(
      label: 'Tiket bantuan aktif dari $requesterName. Deskripsi: $description.',
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
                'Diklaim oleh: ${widget.request.volunteerName ?? 'Relawan aktif'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: widget.isLoading
                            ? null
                            : () {
                                ref
                                    .read(volunteerControllerProvider.notifier)
                                    .resolveHelpRequest(widget.request.id);
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Selesai'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: widget.isLoading
                            ? null
                            : () {
                                ref
                                    .read(volunteerControllerProvider.notifier)
                                    .cancelClaim(widget.request.id);
                              },
                        icon: const Icon(Icons.undo),
                        label: const Text('Batal'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Percakapan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: messagesAsync.when(
                  loading: () {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  error: (error, _) {
                    return Center(
                      child: Text(
                        'Gagal memuat pesan.\n$error',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada pesan koordinasi.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _MessageBubble(
                          message: messages[index],
                        );
                      },
                    );
                  },
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
                        if (!widget.isLoading) {
                          _sendMessage();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tulis pesan koordinasi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    height: 48,
                    child: FilledButton(
                      onPressed: widget.isLoading ? null : _sendMessage,
                      child: widget.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
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
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final text = message.messageText?.trim().isEmpty ?? true
        ? '[Pesan suara]'
        : message.messageText!.trim();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName.isEmpty
                  ? 'Relawan TemanNetra'
                  : message.senderName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(text),
            const SizedBox(height: 4),
            Text(
              _formatCreatedAt(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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

class _EmptyActiveClaimState extends StatelessWidget {
  const _EmptyActiveClaimState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada tiket bantuan yang sedang Anda tangani.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ActiveClaimError extends StatelessWidget {
  final String message;

  const _ActiveClaimError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Gagal memuat klaim aktif.\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
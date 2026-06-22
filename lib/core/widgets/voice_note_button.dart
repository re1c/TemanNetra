import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import '../utils/haptic_service.dart';

class VoiceNoteButton extends ConsumerStatefulWidget {
  final Future<void> Function(String voicePath) onVoiceReady;
  final bool isDisabled;
  final bool fullWidth;
  final double height;
  final double fontSize;
  final bool isCompact;
  final ValueChanged<bool>? onRecordingChanged;
  final String? label;
  final IconData? icon;

  const VoiceNoteButton({
    super.key,
    required this.onVoiceReady,
    this.isDisabled = false,
    this.fullWidth = false,
    this.height = 56,
    this.fontSize = 18,
    this.isCompact = false,
    this.onRecordingChanged,
    this.label,
    this.icon,
  });

  @override
  ConsumerState<VoiceNoteButton> createState() => _VoiceNoteButtonState();
}

class _VoiceNoteButtonState extends ConsumerState<VoiceNoteButton> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon belum diberikan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 24000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    if (mounted) {
      setState(() {
        _isRecording = true;
      });
      widget.onRecordingChanged?.call(true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();

    if (mounted) {
      setState(() {
        _isRecording = false;
      });
      widget.onRecordingChanged?.call(false);
    }

    if (path == null || path.isEmpty) {
      return;
    }

    await widget.onVoiceReady(path);
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording || _isBusy) return;

    setState(() {
      _isBusy = true;
    });

    try {
      final path = await _recorder.stop();

      final haptic = ref.read(hapticServiceProvider);
      await haptic.vibrateClick();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await haptic.vibrateClick();

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // Abaikan error jika gagal menghapus file
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isBusy = false;
        });
        widget.onRecordingChanged?.call(false);
      }
    }
  }

  Future<void> _onPressed() async {
    if (widget.isDisabled || _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses voice note: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Semantics(
              label: 'Kirim Rekaman. Ketuk dua kali untuk berhenti dan mengirim rekaman.',
              button: true,
              child: SizedBox(
                height: widget.height,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF81C784),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: widget.isDisabled || _isBusy ? null : _onPressed,
                  child: _isBusy
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Kirim Rekaman',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: widget.fontSize - 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Semantics(
              label: 'Batalkan rekaman suara.',
              button: true,
              child: SizedBox(
                height: widget.height,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: widget.isDisabled || _isBusy ? null : _cancelRecording,
                  child: Text(
                    'Batalkan',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: widget.fontSize - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.isCompact) {
      return Semantics(
        label: 'Tombol rekam suara.',
        button: true,
        child: SizedBox(
          width: widget.height,
          height: widget.height,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
            ),
            onPressed: widget.isDisabled || _isBusy ? null : _onPressed,
            icon: _isBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.mic, size: 28),
          ),
        ),
      );
    }

    final buttonLabel = widget.label ?? 'Rekam Suara';
    final buttonChild = _isBusy
        ? const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.black,
            ),
          )
        : Text(
            buttonLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
            ),
          );

    return Semantics(
      label: 'Tombol rekam suara.',
      button: true,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        height: widget.height,
        child: widget.icon != null
            ? FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: widget.isDisabled || _isBusy ? null : _onPressed,
                icon: Icon(widget.icon, size: 28),
                label: buttonChild,
              )
            : FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: widget.isDisabled || _isBusy ? null : _onPressed,
                child: buttonChild,
              ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

class VoiceNoteButton extends StatefulWidget {
  final Future<void> Function(String voicePath) onVoiceReady;
  final bool isDisabled;

  const VoiceNoteButton({
    super.key,
    required this.onVoiceReady,
    this.isDisabled = false,
  });

  @override
  State<VoiceNoteButton> createState() => _VoiceNoteButtonState();
}

class _VoiceNoteButtonState extends State<VoiceNoteButton> {
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
    final path = '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    if (mounted) {
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();

    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }

    if (path == null || path.isEmpty) {
      return;
    }

    await widget.onVoiceReady(path);
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
    return Semantics(
      label: _isRecording
          ? 'Sedang merekam voice note. Ketuk dua kali untuk berhenti dan mengirim.'
          : 'Tombol rekam voice note.',
      button: true,
      child: SizedBox(
        width: 56,
        height: 48,
        child: OutlinedButton(
          onPressed: widget.isDisabled || _isBusy ? null : _onPressed,
          child: _isBusy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isRecording ? Icons.stop : Icons.mic),
        ),
      ),
    );
  }
}
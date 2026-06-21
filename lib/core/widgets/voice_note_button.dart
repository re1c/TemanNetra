import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

class VoiceNoteButton extends StatefulWidget {
  final Future<void> Function(String voicePath) onVoiceReady;
  final bool isDisabled;
  final bool fullWidth;
  final double height;
  final double fontSize;

  const VoiceNoteButton({
    super.key,
    required this.onVoiceReady,
    this.isDisabled = false,
    this.fullWidth = false,
    this.height = 56,
    this.fontSize = 18,
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
    final buttonText = _isRecording ? 'Kirim Rekaman' : 'Rekam Suara';

    return Semantics(
      label: _isRecording
          ? 'Sedang merekam. Ketuk dua kali untuk berhenti dan mengirim rekaman.'
          : 'Tombol rekam suara.',
      button: true,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        height: widget.height,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                _isRecording ? Colors.redAccent : const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
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
                  buttonText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

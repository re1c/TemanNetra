import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen(
      (state) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      },
    );

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _isPlaying
          ? 'Voice note sedang diputar. Ketuk dua kali untuk berhenti.'
          : 'Voice note tersedia. Ketuk dua kali untuk memutar.',
      button: true,
      child: SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _toggleAudio,
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
          label: Text(_isPlaying ? 'Berhenti' : 'Putar Voice Note'),
        ),
      ),
    );
  }
}
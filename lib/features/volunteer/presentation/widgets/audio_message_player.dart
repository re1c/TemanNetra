import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool autoPlay;
  final VoidCallback? onAutoPlayStarted;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    this.autoPlay = false,
    this.onAutoPlayStarted,
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
  bool _hasAutoPlayed = false;

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

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoPlayOnce();
      });
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _autoPlayOnce() async {
    if (_hasAutoPlayed || !mounted) {
      return;
    }

    _hasAutoPlayed = true;
    widget.onAutoPlayStarted?.call();

    await _playAudio();
  }

  Future<void> _playAudio() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _audioPlayer.stop();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _stopAudio();
    } else {
      await _playAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonText =
        _isPlaying ? 'Berhenti Memutar' : 'Putar Voice Note';

    return Semantics(
      label: _isPlaying
          ? 'Voice note sedang diputar. Ketuk dua kali untuk berhenti.'
          : 'Voice note tersedia. Ketuk dua kali untuk memutar.',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFD700),
            side: const BorderSide(
              color: Color(0xFFFFD700),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _toggleAudio,
          child: _isLoading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFFFD700),
                  ),
                )
              : Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
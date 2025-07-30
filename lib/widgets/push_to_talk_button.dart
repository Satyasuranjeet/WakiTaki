import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PushToTalkButton extends StatefulWidget {
  final Function(bool) onTalkStateChanged;

  const PushToTalkButton({Key? key, required this.onTalkStateChanged})
    : super(key: key);

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton>
    with SingleTickerProviderStateMixin {
  bool _isTalking = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startTalking() async {
    setState(() {
      _isTalking = true;
    });
    _animationController.forward();
    widget.onTalkStateChanged(true);
    await _audioPlayer.play(AssetSource('sounds/start_talk.mp3'));
  }

  void _stopTalking() async {
    setState(() {
      _isTalking = false;
    });
    _animationController.reverse();
    widget.onTalkStateChanged(false);
    await _audioPlayer.play(AssetSource('sounds/stop_talk.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startTalking(),
      onTapUp: (_) => _stopTalking(),
      onTapCancel: _stopTalking,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isTalking ? Colors.red : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: (_isTalking ? Colors.red : Colors.blue).withOpacity(
                      0.3,
                    ),
                    spreadRadius: _isTalking ? 20 : 10,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                _isTalking ? Icons.mic : Icons.mic_off,
                size: 80,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';
import '../widgets/push_to_talk_button.dart';

class WalkieScreen extends StatefulWidget {
  final String roomId;
  final String username;

  const WalkieScreen({Key? key, required this.roomId, required this.username})
    : super(key: key);

  @override
  State<WalkieScreen> createState() => _WalkieScreenState();
}

class _WalkieScreenState extends State<WalkieScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  bool _isMuted = false;
  final List<String> _connectedUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    _webrtcService.onUserJoined = (username) {
      setState(() {
        _connectedUsers.add(username);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$username joined the room')));
    };

    _webrtcService.onUserLeft = (username) {
      setState(() {
        _connectedUsers.remove(username);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$username left the room')));
    };

    await _webrtcService.initialize(widget.roomId, widget.username);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _webrtcService.toggleMicrophone(!_isMuted);
  }

  @override
  void dispose() {
    _webrtcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId}'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: _toggleMute,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Users (${_connectedUsers.length + 1})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _connectedUsers.length + 1,
                    itemBuilder: (context, index) {
                      final username =
                          index == 0
                              ? '${widget.username} (You)'
                              : _connectedUsers[index - 1];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(username),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hold to Talk',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  PushToTalkButton(
                    onTalkStateChanged: (isTalking) {
                      _webrtcService.toggleMicrophone(isTalking && !_isMuted);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Press and hold the button to transmit',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

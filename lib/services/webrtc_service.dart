import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final SignalingService _signalingService = SignalingService();

  Function(String)? onUserJoined;
  Function(String)? onUserLeft;

  Future<void> initialize(String roomId, String username) async {
    await _createPeerConnection();
    await _getUserMedia();

    _signalingService.connect(roomId, username);
    _setupSignalingCallbacks();
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:global.stun.twilio.com:3478'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _signalingService.sendIceCandidate({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }, 'all'); // Broadcast to all users
    };

    _peerConnection!.onIceConnectionState = (state) {
      print('ICE Connection State: $state');
    };

    _peerConnection!.onTrack = (event) {
      print('Received remote track');
    };
  }

  Future<void> _getUserMedia() async {
    final constraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  void _setupSignalingCallbacks() {
    _signalingService.onUserJoined = (username) {
      print('User joined: $username');
      onUserJoined?.call(username);
      _createOffer(username);
    };

    _signalingService.onUserLeft = (username) {
      print('User left: $username');
      onUserLeft?.call(username);
    };

    _signalingService.onOfferReceived = (data) async {
      await _handleOffer(data);
    };

    _signalingService.onAnswerReceived = (data) async {
      await _handleAnswer(data);
    };

    _signalingService.onIceCandidateReceived = (data) async {
      await _handleIceCandidate(data);
    };
  }

  Future<void> _createOffer(String targetUser) async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _signalingService.sendOffer({
      'type': offer.type,
      'sdp': offer.sdp,
    }, targetUser);
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _signalingService.sendAnswer({
      'type': answer.type,
      'sdp': answer.sdp,
    }, data['fromUser']);
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final answer = RTCSessionDescription(
      data['answer']['sdp'],
      data['answer']['type'],
    );
    await _peerConnection!.setRemoteDescription(answer);
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final candidate = RTCIceCandidate(
      data['candidate']['candidate'],
      data['candidate']['sdpMid'],
      data['candidate']['sdpMLineIndex'],
    );
    await _peerConnection!.addCandidate(candidate);
  }

  void toggleMicrophone(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    _signalingService.disconnect();
  }
}

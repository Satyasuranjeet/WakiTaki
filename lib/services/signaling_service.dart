import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignalingService {
  static const String serverUrl = 'https://waki-taki-signal.onrender.com';

  late IO.Socket socket;
  String? roomId;
  String? username;

  Function(Map<String, dynamic>)? onOfferReceived;
  Function(Map<String, dynamic>)? onAnswerReceived;
  Function(Map<String, dynamic>)? onIceCandidateReceived;
  Function(String)? onUserJoined;
  Function(String)? onUserLeft;

  void connect(String roomId, String username) {
    this.roomId = roomId;
    this.username = username;

    print('🔄 Attempting to connect to: $serverUrl');
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'timeout': 20000,
    });

    socket.onConnect((_) {
      print('✅ Connected to signaling server successfully!');
      socket.emit('join-room', {'roomId': roomId, 'username': username});
    });

    socket.onConnectError((error) {
      print('❌ Connect error: $error');
    });

    socket.onDisconnect((_) => print('🔌 Disconnected from signaling server'));

    socket.on('user-joined', (data) {
      onUserJoined?.call(data['username']);
    });

    socket.on('user-left', (data) {
      onUserLeft?.call(data['username']);
    });

    socket.on('offer', (data) {
      onOfferReceived?.call(data);
    });

    socket.on('answer', (data) {
      onAnswerReceived?.call(data);
    });

    socket.on('ice-candidate', (data) {
      onIceCandidateReceived?.call(data);
    });
  }

  void sendOffer(Map<String, dynamic> offer, String targetUser) {
    socket.emit('offer', {
      'offer': offer,
      'targetUser': targetUser,
      'fromUser': username,
    });
  }

  void sendAnswer(Map<String, dynamic> answer, String targetUser) {
    socket.emit('answer', {
      'answer': answer,
      'targetUser': targetUser,
      'fromUser': username,
    });
  }

  void sendIceCandidate(Map<String, dynamic> candidate, String targetUser) {
    socket.emit('ice-candidate', {
      'candidate': candidate,
      'targetUser': targetUser,
      'fromUser': username,
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}

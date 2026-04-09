import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id, liveId, userId, userName, message;
  final String? userPhotoUrl;
  final DateTime timestamp;
  final bool isHost;

  const ChatModel({
    required this.id, required this.liveId, required this.userId,
    required this.userName, required this.message,
    this.userPhotoUrl, required this.timestamp, this.isHost = false,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id, liveId: d['liveId'] ?? '',
      userId: d['userId'] ?? '', userName: d['userName'] ?? '',
      message: d['message'] ?? '', userPhotoUrl: d['userPhotoUrl'],
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHost: d['isHost'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'liveId': liveId, 'userId': userId, 'userName': userName,
    'userPhotoUrl': userPhotoUrl, 'message': message,
    'timestamp': Timestamp.fromDate(timestamp), 'isHost': isHost,
  };
}

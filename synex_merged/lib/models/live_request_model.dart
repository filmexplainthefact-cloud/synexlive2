import 'package:cloud_firestore/cloud_firestore.dart';

class LiveRequestModel {
  final String userId, userName, status;
  final String? userPhotoUrl;
  final DateTime requestedAt;

  const LiveRequestModel({
    required this.userId, required this.userName, required this.status,
    this.userPhotoUrl, required this.requestedAt,
  });

  factory LiveRequestModel.fromMap(String uid, Map<String, dynamic> d) =>
    LiveRequestModel(
      userId: uid, userName: d['name'] ?? '',
      userPhotoUrl: d['photoUrl'], status: d['status'] ?? 'pending',
      requestedAt: (d['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
}

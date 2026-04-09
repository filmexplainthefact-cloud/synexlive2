import 'package:cloud_firestore/cloud_firestore.dart';

class LiveModel {
  final String id, hostId, hostName, title;
  final String? hostPhotoUrl, description;
  final List<String> speakers, blockedUsers, mutedSpeakers;
  final bool isLive;
  final int viewerCount;
  final DateTime startedAt;
  final DateTime? endedAt;

  const LiveModel({
    required this.id, required this.hostId, required this.hostName,
    required this.title, this.hostPhotoUrl, this.description,
    this.speakers = const [], this.blockedUsers = const [],
    this.mutedSpeakers = const [], this.isLive = true,
    this.viewerCount = 0, required this.startedAt, this.endedAt,
  });

  factory LiveModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LiveModel(
      id: doc.id, hostId: d['hostId'] ?? '', hostName: d['hostName'] ?? '',
      title: d['title'] ?? '', hostPhotoUrl: d['hostPhotoUrl'],
      description: d['description'],
      speakers: List<String>.from(d['speakers'] ?? []),
      blockedUsers: List<String>.from(d['blockedUsers'] ?? []),
      mutedSpeakers: List<String>.from(d['mutedSpeakers'] ?? []),
      isLive: d['isLive'] ?? false, viewerCount: d['viewerCount'] ?? 0,
      startedAt: (d['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (d['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'hostId': hostId, 'hostName': hostName, 'title': title,
    'hostPhotoUrl': hostPhotoUrl, 'description': description,
    'speakers': speakers, 'blockedUsers': blockedUsers,
    'mutedSpeakers': mutedSpeakers, 'isLive': isLive,
    'viewerCount': viewerCount,
    'startedAt': Timestamp.fromDate(startedAt),
    'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
  };
}

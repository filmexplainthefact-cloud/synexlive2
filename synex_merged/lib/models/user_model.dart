import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid, name, email;
  final String? photoUrl, bio, fcmToken, ign, squadName, freefireUid;
  final int followersCount, followingCount;
  final num balance;
  final int tickets, level, xp;
  final DateTime createdAt;

  const UserModel({
    required this.uid, required this.name, required this.email,
    this.photoUrl, this.bio, this.fcmToken, this.ign, this.squadName, this.freefireUid,
    this.followersCount = 0, this.followingCount = 0,
    this.balance = 0, this.tickets = 0, this.level = 1, this.xp = 0,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, name: d['name'] ?? '', email: d['email'] ?? '',
      photoUrl: d['photoUrl'], bio: d['bio'], fcmToken: d['fcmToken'],
      ign: d['ign'], squadName: d['squadName'], freefireUid: d['freefireUid'],
      followersCount: d['followersCount'] ?? 0,
      followingCount: d['followingCount'] ?? 0,
      balance: d['balance'] ?? 0, tickets: d['tickets'] ?? 0,
      level: d['level'] ?? 1, xp: d['xp'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name, 'email': email, 'photoUrl': photoUrl,
    'bio': bio, 'fcmToken': fcmToken, 'ign': ign,
    'squadName': squadName, 'freefireUid': freefireUid,
    'followersCount': followersCount, 'followingCount': followingCount,
    'balance': balance, 'tickets': tickets, 'level': level, 'xp': xp,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserModel copyWith({String? name, String? bio, String? photoUrl,
    String? ign, String? squadName, String? freefireUid, String? fcmToken}) =>
    UserModel(
      uid: uid, name: name ?? this.name, email: email,
      photoUrl: photoUrl ?? this.photoUrl, bio: bio ?? this.bio,
      fcmToken: fcmToken ?? this.fcmToken,
      ign: ign ?? this.ign, squadName: squadName ?? this.squadName,
      freefireUid: freefireUid ?? this.freefireUid,
      followersCount: followersCount, followingCount: followingCount,
      balance: balance, tickets: tickets, level: level, xp: xp,
      createdAt: createdAt,
    );
}

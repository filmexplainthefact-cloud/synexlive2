class AppConstants {
  static const String appName = 'Synex';
  static const String usersCollection    = 'users';
  static const String livesCollection    = 'lives';
  static const String chatsCollection    = 'live_chats';
  static const String requestsCollection = 'live_requests';
  static const String notificationsCol   = 'notifications';
  static const String signalingCol       = 'signaling';
  static const String tournamentsPath    = 'tournaments';
  static const String spinHistoryPath    = 'spinHistory';
  static const String purchasesPath      = 'purchases';
  static const int maxSpeakers    = 6;
  static const int maxChatHistory = 100;
  static const Map<String, dynamic> iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };
  static const String statusPending  = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  static const String roleHost     = 'host';
  static const String roleSpeaker  = 'speaker';
  static const String roleAudience = 'audience';
  static const String errorGeneric = 'Kuch galat hua. Dobara try karo.';
}

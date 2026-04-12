import 'package:flutter/foundation.dart';

class WebRTCService {
  bool _audioEnabled = true;
  bool _videoEnabled = false;

  bool get isAudioEnabled => _audioEnabled;
  bool get isVideoEnabled => _videoEnabled;

  Function(String uid, dynamic stream)? onRemoteStreamAdded;
  Function(String uid)? onRemoteStreamRemoved;

  Future<void> initialize({bool enableVideo = false}) async {
    _videoEnabled = enableVideo;
    _audioEnabled = true;
    debugPrint('WebRTCService: Zego handles audio');
  }

  Future<void> joinChannel(String channelName, {bool isHost = false}) async {}
  Future<void> switchToSpeaker() async { _audioEnabled = true; }
  Future<void> switchToAudience() async {}
  void toggleAudio() => _audioEnabled = !_audioEnabled;
  void toggleVideo() => _videoEnabled = !_videoEnabled;
  void forceMute() => _audioEnabled = false;
  Future<void> switchCamera() async {}
  Future<void> callPeer({required String liveId, required String localUid, required String remoteUid}) async {}
  Future<void> answerCall({required String liveId, required String localUid, required String callerUid, required Map<String, dynamic> offerData}) async {}
  Future<void> leaveChannel() async {}
  Future<void> dispose() async {}
}

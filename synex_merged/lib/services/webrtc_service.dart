import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRTCService {
  static const String _appId = '9dd70ee991a24b24bf96e72289ec97c7';

  RtcEngine? _engine;
  bool _audioEnabled = true;
  bool _videoEnabled = false;
  bool _initialized = false;
  String? _currentChannel;

  bool get isAudioEnabled => _audioEnabled;
  bool get isVideoEnabled => _videoEnabled;

  Function(String uid, dynamic stream)? onRemoteStreamAdded;
  Function(String uid)? onRemoteStreamRemoved;

  Future<void> initialize({bool enableVideo = false}) async {
    if (_initialized) return;
    try {
      await Permission.microphone.request();
      if (enableVideo) await Permission.camera.request();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // ✅ FIX: 6.3.2 version ke hisaab se event handler
      _engine!.setEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅ Joined channel: ${connection.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('👤 Remote user joined: $remoteUid');
          onRemoteStreamAdded?.call(remoteUid.toString(), null);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, int reason) {
          debugPrint('👋 Remote user offline: $remoteUid');
          onRemoteStreamRemoved?.call(remoteUid.toString());
        },
        onError: (int err, String msg) {
          debugPrint('❌ Agora Error: $err - $msg');
        },
      ));

      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        AudioProfileType.audioProfileMusicHighQuality,
        AudioScenarioType.audioScenarioChatroom,
      );
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);

      _videoEnabled = enableVideo;
      _audioEnabled = true;
      _initialized = true;
      debugPrint('✅ Agora initialized');
    } catch (e) {
      debugPrint('❌ Agora init error: $e');
    }
  }

  // 🔽 Baaki saare functions (joinChannel, switchToSpeaker, etc.) WAISE HI RAHENGE
  // ... (joinChannel, switchToSpeaker, toggleAudio, dispose wagera wahi copy karna)
  
  Future<void> joinChannel(String channelName, {bool isHost = false}) async {
    if (!_initialized || _engine == null) await initialize();
    try {
      _currentChannel = channelName;
      await _engine!.setClientRole(
        role: isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
      );
      await _engine!.joinChannel(
        token: '',
        channelId: channelName,
        info: null,
        uid: 0,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: isHost,
          publishCameraTrack: false,
          clientRoleType: isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
        ),
      );
      debugPrint('🎙️ Joined channel: $channelName as ${isHost ? "HOST" : "AUDIENCE"}');
    } catch (e) {
      debugPrint('❌ Agora joinChannel error: $e');
    }
  }

  Future<void> switchToSpeaker() async {
    if (!_initialized || _engine == null) return;
    try {
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.muteLocalAudioStream(false);
      _audioEnabled = true;
      debugPrint('🎤 Switched to speaker');
    } catch (e) {
      debugPrint('switchToSpeaker error: $e');
    }
  }

  void toggleAudio() {
    if (!_initialized || _engine == null) return;
    _audioEnabled = !_audioEnabled;
    _engine!.muteLocalAudioStream(!_audioEnabled);
  }

  void forceMute() {
    if (!_initialized || _engine == null) return;
    _audioEnabled = false;
    _engine!.muteLocalAudioStream(true);
  }

  Future<void> leaveChannel() async {
    if (!_initialized || _engine == null) return;
    try {
      await _engine!.leaveChannel();
      _currentChannel = null;
    } catch (e) {
      debugPrint('leaveChannel error: $e');
    }
  }

  Future<void> dispose() async {
    if (_engine == null) return;
    try {
      await leaveChannel();
      await _engine!.release();
      _engine = null;
      _initialized = false;
    } catch (e) {
      debugPrint('dispose error: $e');
    }
  }
  
  // Baki functions (callPeer, answerCall, switchCamera, etc.) agar chahiye toh yahan add karo
  Future<void> callPeer({required String liveId, required String localUid, required String remoteUid}) async {
    await joinChannel(liveId, isHost: true);
  }
  
  Future<void> answerCall({required String liveId, required String localUid, required String callerUid, required Map<String, dynamic> offerData}) async {
    await joinChannel(liveId, isHost: false);
  }
  
  Future<void> switchCamera() async {}
  
  void toggleVideo() {
    _videoEnabled = !_videoEnabled;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/live_service.dart';
import '../../services/webrtc_service.dart'
    if (dart.library.html) '../../services/webrtc_service.dart';
import '../../models/live_model.dart';
import '../../models/chat_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/app_constants.dart';
import '../../widgets/speaker_tile.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/request_tile.dart';
import '../home_screen.dart';

class LiveScreen extends StatefulWidget {
  final String liveId;
  final bool isHost;
  const LiveScreen({super.key, required this.liveId, this.isHost = false});
  @override State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with TickerProviderStateMixin {
  final _webrtc = WebRTCService();
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late TabController _tabCtrl;

  bool _micOn = true;
  bool _videoOn = false;
  bool _showRequests = false;
  bool _handRaised = false;
  bool _webrtcReady = false;
  String _myRole = AppConstants.roleAudience;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _initSession();
  }

  Future<void> _initSession() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserId ?? '';
    
    await LiveService.incrementViewer(widget.liveId);
    
    if (widget.isHost) {
      setState(() => _myRole = AppConstants.roleHost);
    }
    
    if (widget.isHost) {
      try {
        await _webrtc.initialize(enableVideo: false);
        setState(() => _webrtcReady = true);
        await _webrtc.joinChannel(widget.liveId, isHost: true);
        debugPrint('🎙️ Host joined channel: ${widget.liveId}');
      } catch (e) {
        debugPrint('Host init error: $e');
        AppHelpers.showToast('Mic permission denied', isError: true);
      }
    } else {
      try {
        await _webrtc.initialize(enableVideo: false);
        await _webrtc.joinChannel(widget.liveId, isHost: false);
        debugPrint('👂 Audience joined channel: ${widget.liveId}');
      } catch (e) {
        debugPrint('Audience join error: $e');
      }
    }
    
    LiveService.getLiveSession(widget.liveId).listen((live) async {
      if (live == null) return;
      if (live.speakers.contains(uid) && _myRole == AppConstants.roleAudience) {
        setState(() => _myRole = AppConstants.roleSpeaker);
        try {
          if (!_webrtcReady) {
            await _webrtc.initialize(enableVideo: false);
            setState(() => _webrtcReady = true);
          }
          await _webrtc.switchToSpeaker();
          debugPrint('🎤 Switched to speaker!');
        } catch (e) {
          debugPrint('Switch to speaker error: $e');
        }
      }
      if (live.mutedSpeakers.contains(uid) && _myRole == AppConstants.roleSpeaker) {
        _webrtc.forceMute();
        setState(() => _micOn = false);
      }
    });
  }

  @override
  void dispose() {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserId ?? '';
    LiveService.decrementViewer(widget.liveId);
    LiveService.clearRequest(widget.liveId, uid);
    _webrtc.leaveChannel();
    _webrtc.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _endLive() async {
    final confirm = await AppHelpers.showConfirmDialog(context,
      title: 'End Live?', message: 'This will end the session for everyone.',
      confirmText: 'End Live', isDestructive: true);
    if (!confirm || !mounted) return;
    await LiveService.endLive(widget.liveId);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  Future<void> _leaveLive() async {
    final auth  = context.read<AuthService>();
    final uid   = auth.currentUserId ?? '';
    if (_myRole == AppConstants.roleSpeaker) {
      await LiveService.removeSpeaker(widget.liveId, uid);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;
    _chatCtrl.clear();
    await LiveService.sendChat(
      liveId: widget.liveId, userId: user.uid,
      userName: user.name, userPhotoUrl: user.photoUrl,
      message: text, isHost: widget.isHost,
    );
    _scrollToBottom();
  }

  Future<void> _raiseHand() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser; if (user == null) return;
    setState(() => _handRaised = true);
    await LiveService.raiseHand(
      liveId: widget.liveId, userId: user.uid,
      userName: user.name, userPhotoUrl: user.photoUrl);
    AppHelpers.showToast('Hand raised! Waiting for host...');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid  = auth.currentUserId ?? '';

    return StreamBuilder<LiveModel?>(
      stream: LiveService.getLiveSession(widget.liveId),
      builder: (context, snap) {
        final live = snap.data;
        if (live == null) {
          return Scaffold(backgroundColor: AppTheme.bgDark,
            body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)));
        }
        if (!live.isLive && !widget.isHost) {
          return Scaffold(backgroundColor: AppTheme.bgDark,
            body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.tv_off_rounded, color: AppTheme.textSec, size: 60),
              const SizedBox(height: 16),
              const Text('This live has ended', style: TextStyle(color: AppTheme.textPri, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                child: const Text('Back to Home')),
            ])));
        }
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: SafeArea(child: Column(children: [
            _buildTopBar(live, uid),
            Expanded(child: Column(children: [
              _buildSpeakers(live, uid),
              const Divider(height: 1, color: AppTheme.border),
              if (widget.isHost && _showRequests) _buildRequests(live),
              Expanded(child: _buildChat(uid)),
            ])),
            _buildBottomBar(live, uid),
          ])),
        );
      },
    );
  }

  Widget _buildTopBar(LiveModel live, String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: AppTheme.surface, border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.liveRed, borderRadius: BorderRadius.circular(6)),
          child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(live.title, style: const TextStyle(color: AppTheme.textPri, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('by ${live.hostName}', style: const TextStyle(color: AppTheme.textSec, fontSize: 12)),
        ])),
        Row(children: [
          const Icon(Icons.remove_red_eye_outlined, color: AppTheme.textSec, size: 16),
          const SizedBox(width: 4),
          Text(AppHelpers.formatCount(live.viewerCount),
            style: const TextStyle(color: AppTheme.textSec, fontSize: 13)),
        ]),
        const SizedBox(width: 12),
        if (widget.isHost) StreamBuilder<List>(
          stream: LiveService.getRequestsStream(widget.liveId),
          builder: (_, snap) {
            final count = snap.data?.length ?? 0;
            return Stack(children: [
              IconButton(
                onPressed: () => setState(() => _showRequests = !_showRequests),
                icon: Icon(Icons.front_hand_outlined,
                  color: count > 0 ? AppTheme.accent : AppTheme.textSec)),
              if (count > 0) Positioned(top: 6, right: 6,
                child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle))),
            ]);
          }),
        TextButton(
          onPressed: widget.isHost ? _endLive : _leaveLive,
          child: Text(widget.isHost ? 'End' : 'Leave',
            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildSpeakers(LiveModel live, String uid) {
    final all = [live.hostId, ...live.speakers];
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('On Stage (${all.length})',
            style: const TextStyle(color: AppTheme.textSec, fontSize: 12, fontWeight: FontWeight.w600))),
        Wrap(spacing: 8, runSpacing: 8, children: all.map((speakerId) {
          final isHostTile = speakerId == live.hostId;
          final isMuted = live.mutedSpeakers.contains(speakerId);
          return SizedBox(width: 80,
            child: SpeakerTile(
              userId: speakerId, userName: isHostTile ? live.hostName : 'Speaker',
              photoUrl: isHostTile ? live.hostPhotoUrl : null,
              isMuted: isMuted, isHost: isHostTile,
              canControl: widget.isHost && !isHostTile,
              onMute: () async {
                if (isMuted) await LiveService.unmuteSpeaker(widget.liveId, speakerId);
                else await LiveService.muteSpeaker(widget.liveId, speakerId);
              },
              onRemove: () async {
                final ok = await AppHelpers.showConfirmDialog(context,
                  title: 'Remove Speaker', message: 'Remove this speaker from stage?',
                  isDestructive: true);
                if (ok) await LiveService.removeSpeaker(widget.liveId, speakerId);
              },
              onBlock: () async {
                final ok = await AppHelpers.showConfirmDialog(context,
                  title: 'Block User', message: 'Block this user from the live?',
                  isDestructive: true);
                if (ok) await LiveService.blockUser(widget.liveId, speakerId);
              },
            ));
        }).toList()),
      ]),
    );
  }

  Widget _buildRequests(LiveModel live) {
    return StreamBuilder(
      stream: LiveService.getRequestsStream(widget.liveId),
      builder: (_, snap) {
        final reqs = snap.data ?? [];
        if (reqs.isEmpty) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(color: AppTheme.surface,
            border: const Border(bottom: BorderSide(color: AppTheme.border))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Raise Hand Requests',
                style: TextStyle(color: AppTheme.textPri, fontSize: 13, fontWeight: FontWeight.w700))),
            Expanded(child: ListView.builder(
              itemCount: reqs.length,
              itemBuilder: (_, i) => RequestTile(
                request: reqs[i],
                onAccept: () => LiveService.acceptRequest(liveId: widget.liveId, userId: reqs[i].userId),
                onReject: () => LiveService.rejectRequest(liveId: widget.liveId, userId: reqs[i].userId),
              ),
            )),
          ]),
        );
      },
    );
  }

  Widget _buildChat(String uid) {
    return StreamBuilder<List<ChatModel>>(
      stream: LiveService.getChatStream(widget.liveId),
      builder: (_, snap) {
        final chats = snap.data ?? [];
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.builder(
          controller: _scrollCtrl,
          itemCount: chats.length,
          itemBuilder: (_, i) => ChatBubble(chat: chats[i], isMe: chats[i].userId == uid),
        );
      },
    );
  }

  Widget _buildBottomBar(LiveModel live, String uid) {
    final isSpeaker = _myRole == AppConstants.roleSpeaker || widget.isHost;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: TextField(
            controller: _chatCtrl,
            style: const TextStyle(color: AppTheme.textPri, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
              filled: true, fillColor: AppTheme.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _sendChat(),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendChat,
            child: Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          if (isSpeaker) _actionBtn(
            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: _micOn ? 'Mute' : 'Unmute',
            color: _micOn ? AppTheme.speakerGreen : AppTheme.accent,
            onTap: () {
              _webrtc.toggleAudio();
              setState(() => _micOn = !_micOn);
            }),
          if (_myRole == AppConstants.roleAudience)
            StreamBuilder<String?>(
              stream: LiveService.getUserRequestStatus(widget.liveId, uid),
              builder: (_, snap) {
                final status = snap.data;
                String label = 'Raise Hand';
                Color color = AppTheme.primary;
                IconData icon = Icons.front_hand_outlined;
                if (status == AppConstants.statusPending) { label = 'Pending'; color = AppTheme.textSec; }
                if (status == AppConstants.statusAccepted) { label = 'Accepted'; color = AppTheme.speakerGreen; }
                if (status == AppConstants.statusRejected) { label = 'Rejected'; color = AppTheme.accent; }
                return _actionBtn(icon: icon, label: label, color: color,
                  onTap: status == null ? _raiseHand : null);
              }),
          if (isSpeaker) _actionBtn(
            icon: _videoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label: _videoOn ? 'Cam Off' : 'Cam On',
            color: _videoOn ? AppTheme.primary : AppTheme.textSec,
            onTap: () {
              _webrtc.toggleVideo();
              setState(() => _videoOn = !_videoOn);
            }),
          _actionBtn(icon: Icons.people_outline_rounded, label: 'People',
            color: AppTheme.textSec, onTap: () {}),
        ]),
      ]),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ]),
    );
  }
}

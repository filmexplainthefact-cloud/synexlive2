import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/user_avatar.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final _nameCtrl      = TextEditingController();
  final _bioCtrl       = TextEditingController();
  final _ignCtrl       = TextEditingController();
  final _squadCtrl     = TextEditingController();
  final _ffUidCtrl     = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose(); _ignCtrl.dispose();
    _squadCtrl.dispose(); _ffUidCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final err = await auth.updateProfile(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      ign: _ignCtrl.text.trim(),
      squadName: _squadCtrl.text.trim(),
      freefireUid: _ffUidCtrl.text.trim(),
    );
    setState(() { _saving = false; _editing = false; });
    if (!mounted) return;
    if (err != null) AppHelpers.showSnackBar(context, err, isError: true);
    else AppHelpers.showSnackBar(context, 'Profile update ho gaya!');
  }

  Future<void> _signOut() async {
    final ok = await AppHelpers.showConfirmDialog(context,
      title: 'Logout', message: 'Logout karna chahte ho?',
      confirmText: 'Logout', isDestructive: true);
    if (!ok || !mounted) return;
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final isMe = auth.currentUserId == widget.userId;

    if (user == null) {
      return const Scaffold(backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.cyan)));
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bg2,
        title: const Text('Profile'),
        actions: [
          if (isMe) TextButton(
            onPressed: () {
              if (_editing) {
                setState(() => _editing = false);
              } else {
                _nameCtrl.text = user.name;
                _bioCtrl.text = user.bio ?? '';
                _ignCtrl.text = user.ign ?? '';
                _squadCtrl.text = user.squadName ?? '';
                _ffUidCtrl.text = user.freefireUid ?? '';
                setState(() => _editing = true);
              }
            },
            child: Text(_editing ? 'Cancel' : 'Edit',
              style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w700))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Avatar + info
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 80,
                showBorder: true, borderColor: AppTheme.cyan),
              const SizedBox(height: 12),
              Text(user.name, style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (user.squadName != null && user.squadName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people, color: Colors.white60, size: 14),
                  const SizedBox(width: 4),
                  Text(user.squadName!, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
              ],
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _statChip('Level', '${user.level}'),
                const SizedBox(width: 16),
                _statChip('Tickets', '${user.tickets}'),
                const SizedBox(width: 16),
                _statChip('XP', '${user.xp}'),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Gaming stats (from gaming DB)
          if (auth.currentUserId != null)
            StreamBuilder<Map<String, dynamic>>(
              stream: TournamentService.getUserGamingData(auth.currentUserId!),
              builder: (_, snap) {
                final d = snap.data ?? {};
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Player Stats', style: TextStyle(
                      color: AppTheme.cyan, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _statBox('Wins', '${d['wins'] ?? 0}', AppTheme.gold),
                      const SizedBox(width: 8),
                      _statBox('K/D', '${d['kd'] ?? '0.0'}', AppTheme.cyan),
                      const SizedBox(width: 8),
                      _statBox('Played', '${d['played'] ?? 0}', AppTheme.textSec),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _statBox('Kills', '${d['kills'] ?? 0}', AppTheme.danger),
                      const SizedBox(width: 8),
                      _statBox('Top 3', '${d['top3'] ?? 0}', AppTheme.gold),
                      const SizedBox(width: 8),
                      _statBox('Win%', '${d['winPct'] ?? 0}%', AppTheme.success),
                    ]),
                  ]),
                );
              }),

          const SizedBox(height: 16),

          // Edit section
          if (_editing) ...[
            _editField('Free Fire UID', _ffUidCtrl, Icons.games),
            const SizedBox(height: 10),
            _editField('In-Game Name (IGN)', _ignCtrl, Icons.person),
            const SizedBox(height: 10),
            _editField('Display Name', _nameCtrl, Icons.badge),
            const SizedBox(height: 10),
            _editField('Squad / Team Name', _squadCtrl, Icons.groups),
            const SizedBox(height: 10),
            _editField('Bio', _bioCtrl, Icons.info_outline, maxLines: 2),
            const SizedBox(height: 20),
            CustomButton(label: 'Save Changes', isLoading: _saving, onPressed: _save),
            const SizedBox(height: 16),
          ],

          // Sign out
          if (isMe && !_editing) ...[
            const SizedBox(height: 8),
            CustomButton(label: 'Logout', isLoading: false, onPressed: _signOut,
              variant: ButtonVariant.outlined, color: AppTheme.danger),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _statChip(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);

  Widget _statBox(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppTheme.card2, borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: AppTheme.textSec, fontSize: 10)),
    ]),
  ));

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card2, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSec, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(icon, color: AppTheme.textSec, size: 16),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: ctrl, maxLines: maxLines,
            style: const TextStyle(color: AppTheme.textPri, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none, isDense: true,
              contentPadding: EdgeInsets.zero),
          )),
        ]),
      ]),
    );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/user_avatar.dart';
import 'home_screen.dart';
import 'tournaments_screen.dart';
import 'spin_screen.dart';
import 'store_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'live/go_live_screen.dart';
import 'auth/login_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  bool _menuOpen = false;

  final List<Widget> _pages = const [
    HomeScreen(),
    TournamentsScreen(),
    SpinScreen(),
    StoreScreen(),
  ];

  void _openMenu() => setState(() => _menuOpen = true);
  void _closeMenu() => setState(() => _menuOpen = false);

  Future<void> _signOut() async {
    _closeMenu();
    final ok = await AppHelpers.showConfirmDialog(context,
      title: 'Logout', message: 'Kya aap logout karna chahte ho?',
      confirmText: 'Logout', isDestructive: true);
    if (!ok || !mounted) return;
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final uid  = auth.currentUserId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(children: [
        Column(children: [
          _buildHeader(uid, user?.name ?? 'Player', user?.photoUrl),
          Expanded(child: _pages[_tab]),
        ]),
        if (_menuOpen) ...[
          GestureDetector(onTap: _closeMenu,
            child: Container(color: Colors.black.withOpacity(0.72))),
          _buildSideMenu(auth),
        ],
      ]),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _tab == 0
        ? FloatingActionButton.extended(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GoLiveScreen())),
            backgroundColor: AppTheme.liveRed,
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            label: const Text('Go Live',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))
        : null,
    );
  }

  Widget _buildHeader(String uid, String name, String? photo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.bg2, AppTheme.card]),
        border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: SafeArea(bottom: false, child: Row(children: [
        IconButton(
          onPressed: _openMenu,
          icon: const Icon(Icons.menu_rounded, color: AppTheme.cyan),
          padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        const SizedBox(width: 10),
        const Text('SYNEX', style: TextStyle(
          color: AppTheme.cyan, fontSize: 16,
          fontWeight: FontWeight.w900, letterSpacing: 2)),
        const Spacer(),
        // Wallet balance from gaming DB
        StreamBuilder<Map<String, dynamic>>(
          stream: uid.isNotEmpty
            ? TournamentService.getUserGamingData(uid)
            : const Stream.empty(),
          builder: (_, snap) {
            final bal = snap.data?['balance'] ?? 0;
            final tickets = snap.data?['tickets'] ?? 0;
            return Row(children: [
              // Tickets
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.15),
                  border: Border.all(color: AppTheme.purple.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Icon(Icons.confirmation_num, color: AppTheme.purple, size: 13),
                  const SizedBox(width: 3),
                  Text('$tickets', style: const TextStyle(
                    color: AppTheme.purple, fontSize: 12, fontWeight: FontWeight.w700)),
                ])),
              const SizedBox(width: 6),
              // Balance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.1),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Text('Rs.', style: TextStyle(
                    color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                  Text(AppHelpers.formatMoney(bal),
                    style: const TextStyle(
                      color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                ])),
            ]);
          }),
        const SizedBox(width: 8),
        const Icon(Icons.notifications_outlined, color: AppTheme.textSec, size: 22),
      ])),
    );
  }

  Widget _buildSideMenu(AuthService auth) {
    final user = auth.currentUser;
    return Positioned(
      left: 0, top: 0, bottom: 0, width: 280,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0C1E3D), AppTheme.bg2]),
          border: Border(right: BorderSide(color: AppTheme.border))),
        child: SafeArea(child: Column(children: [
          // User header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, const Color(0xFF0D47A1)])),
            child: Row(children: [
              UserAvatar(name: user?.name ?? 'User', photoUrl: user?.photoUrl,
                size: 52, showBorder: true, borderColor: AppTheme.cyan),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? 'Player',
                  style: const TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w700)),
                Text(user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                // XP bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ((user?.xp ?? 0) % 100) / 100,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    color: AppTheme.cyan)),
                const SizedBox(height: 3),
                Text('Level ${user?.level ?? 1}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ])),
            ])),
          // Nav items
          Expanded(child: ListView(children: [
            const SizedBox(height: 6),
            _sectionLabel('MAIN'),
            _menuItem(Icons.home_outlined, 'Home', 0),
            _menuItem(Icons.emoji_events_outlined, 'Tournaments', 1),
            _menuItem(Icons.casino_outlined, 'Spin Wheel', 2),
            _menuItem(Icons.store_outlined, 'Store', 3),
            const SizedBox(height: 2),
            _sectionLabel('ACCOUNT'),
            _menuItemTap(Icons.person_outline, 'Profile', () {
              _closeMenu();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: auth.currentUserId ?? '')));
            }),
            _menuItemTap(Icons.history, 'History', () {
              _closeMenu();
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()));
            }),
            _menuItemTap(Icons.live_tv_outlined, 'Live Sessions', () {
              _closeMenu(); setState(() => _tab = 0);
            }),
            const Divider(color: AppTheme.border, indent: 16, endIndent: 16),
            _menuItemTap(Icons.logout, 'Logout', _signOut,
              color: AppTheme.danger),
            const SizedBox(height: 20),
          ])),
        ])),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
    child: Text(label, style: const TextStyle(
      color: AppTheme.textSec, fontSize: 10,
      letterSpacing: 1.5, fontWeight: FontWeight.w700)),
  );

  Widget _menuItem(IconData icon, String label, int index) =>
    _menuItemTap(icon, label, () {
      _closeMenu(); setState(() => _tab = index);
    }, isActive: _tab == index);

  Widget _menuItemTap(IconData icon, String label, VoidCallback onTap,
    {bool isActive = false, Color? color}) =>
    InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.cyan.withOpacity(0.08) : null,
          border: isActive
            ? const Border(left: BorderSide(color: AppTheme.cyan, width: 3))
            : null),
        child: Row(children: [
          Icon(icon, color: isActive ? AppTheme.cyan : (color ?? AppTheme.textSec), size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(
            color: isActive ? AppTheme.cyan : (color ?? AppTheme.textPri),
            fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );

  Widget _buildBottomNav() => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppTheme.border))),
    child: BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      backgroundColor: AppTheme.bg2,
      selectedItemColor: AppTheme.cyan,
      unselectedItemColor: AppTheme.textSec,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10, unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events_outlined),
          activeIcon: Icon(Icons.emoji_events), label: 'Tournaments'),
        BottomNavigationBarItem(
          icon: Icon(Icons.casino_outlined),
          activeIcon: Icon(Icons.casino), label: 'Spin'),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store), label: 'Store'),
      ],
    ),
  );
}

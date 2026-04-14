import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'matches_screen.dart';
import 'spin_screen.dart';
import 'wallet_screen.dart';
import 'store_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? userData;
  int _unreadNotifs = 0;
  bool _loadingUser = true;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenNotifs();
    FirebaseService.initNotifications();
  }

  void _loadUserData() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    FirebaseDatabase.instance.ref('users/$uid').onValue.listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      setState(() {
        userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        _loadingUser = false;
      });
    });
  }

  void _listenNotifs() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    FirebaseService.notifStream(uid).listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      final data = event.snapshot.value as Map;
      final unread = data.values.where((v) {
        final m = v as Map;
        return m['read'] == false || m['read'] == null;
      }).length;
      setState(() => _unreadNotifs = unread);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    final screens = [
      HomeScreen(userData: userData),
      MatchesScreen(userData: userData),
      SpinScreen(userData: userData, onUserUpdate: _refreshUser),
      StoreScreen(userData: userData),
      ProfileScreen(userData: userData, onUserUpdate: _refreshUser),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _refreshUser() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('users/$uid').get().then((snap) {
      if (snap.exists && mounted) {
        setState(() {
          userData = Map<String, dynamic>.from(snap.value as Map);
        });
      }
    });
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.emoji_events_rounded, 'label': 'Matches'},
      {'icon': Icons.casino_rounded, 'label': 'Spin'},
      {'icon': Icons.storefront_rounded, 'label': 'Store'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            items[i]['icon'] as IconData,
                            size: 22,
                            color: selected ? AppColors.cyan : AppColors.muted,
                          ),
                          if (i == 0 && _unreadNotifs > 0)
                            Positioned(
                              top: -4, right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_unreadNotifs',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 8, color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: selected ? AppColors.cyan : AppColors.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(top: 2),
                        height: 2,
                        width: selected ? 20 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withOpacity(0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

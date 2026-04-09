import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});
  @override State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;
  bool _isSpinning = false;
  int? _resultIndex;
  double _currentAngle = 0;

  final List<_SpinPrize> prizes = [
    _SpinPrize('Rs.2', const Color(0xFF1565C0), 'cash'),
    _SpinPrize('Rs.5', const Color(0xFF7C4DFF), 'cash'),
    _SpinPrize('Rs.10', const Color(0xFF00897B), 'cash'),
    _SpinPrize('Rs.25', const Color(0xFF1976D2), 'cash'),
    _SpinPrize('Rs.50', const Color(0xFFE65100), 'cash'),
    _SpinPrize('Ticket', const Color(0xFF6A1B9A), 'ticket'),
    _SpinPrize('Better\nLuck!', const Color(0xFF37474F), 'none'),
    _SpinPrize('Rs.2', const Color(0xFF1565C0), 'cash'),
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _spinCtrl.dispose(); super.dispose(); }

  Future<void> _doSpin() async {
    if (_isSpinning) return;
    final auth = context.read<AuthService>();
    final uid  = auth.currentUserId;
    if (uid == null) return;

    final gamingData = await TournamentService.getUserGamingData(uid).first;
    final balance = gamingData['balance'] ?? 0;

    if (balance < 10) {
      AppHelpers.showSnackBar(context, 'Balance kam hai! Min Rs.10 chahiye.', isError: true);
      return;
    }

    setState(() { _isSpinning = true; _resultIndex = null; });

    final result = await TournamentService.doSpin(uid, balance);

    if (result.containsKey('error')) {
      setState(() => _isSpinning = false);
      if (mounted) AppHelpers.showSnackBar(context, result['error'], isError: true);
      return;
    }

    final idx = result['index'] as int;
    final segAngle = (2 * pi) / prizes.length;
    final targetAngle = (4 * pi * 3) + (prizes.length - idx) * segAngle;

    _spinAnim = Tween<double>(begin: _currentAngle, end: _currentAngle + targetAngle)
      .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut));

    _spinCtrl.reset();
    await _spinCtrl.forward();

    _currentAngle = (_currentAngle + targetAngle) % (2 * pi);

    setState(() {
      _isSpinning = false;
      _resultIndex = idx;
    });

    if (mounted) _showResult(result['prize'] as Map<String, dynamic>);
  }

  void _showResult(Map<String, dynamic> prize) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Result!', textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textPri, fontWeight: FontWeight.w800, fontSize: 22)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(prize['label'] as String,
            style: const TextStyle(color: AppTheme.gold, fontSize: 36, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(prize['type'] == 'none' ? 'Agli baar!' : 'Aapka account update ho gaya!',
            style: const TextStyle(color: AppTheme.textSec, fontSize: 13), textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid  = auth.currentUserId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Header
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A0050), Color(0xFF3D0080)]),
            borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Text('Spin The Wheel', style: TextStyle(
              color: AppTheme.textPri, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Luck aazmaao! Cash prizes jeeto', style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Rs.', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                Text('10 per spin', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Wheel
        Stack(alignment: Alignment.center, children: [
          // Glow
          Container(width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)])),
          // Wheel
          AnimatedBuilder(
            animation: _spinAnim,
            builder: (_, __) => Transform.rotate(
              angle: _spinAnim.value,
              child: CustomPaint(
                size: const Size(260, 260),
                painter: _WheelPainter(prizes),
              ),
            ),
          ),
          // Center dot
          Container(width: 24, height: 24,
            decoration: BoxDecoration(
              color: AppTheme.bgDark, shape: BoxShape.circle,
              border: Border.all(color: AppTheme.textSec, width: 2))),
          // Pointer
          Positioned(top: 2, child: Container(
            width: 0, height: 0,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.transparent, width: 10),
                right: BorderSide(color: Colors.transparent, width: 10),
                bottom: BorderSide(color: AppTheme.textPri, width: 24))),
          )),
        ]),
        const SizedBox(height: 28),

        // Spin button
        GestureDetector(
          onTap: _isSpinning ? null : _doSpin,
          child: Container(
            width: 180, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isSpinning
                  ? [AppTheme.textSec, AppTheme.textSec]
                  : [AppTheme.purple, const Color(0xFF4A148C)]),
              borderRadius: BorderRadius.circular(26),
              boxShadow: _isSpinning ? [] : [
                BoxShadow(color: AppTheme.purple.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4))]),
            child: Center(child: _isSpinning
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text('SPIN!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ])),
          ),
        ),
        const SizedBox(height: 28),

        // History
        if (uid != null) ...[
          const Align(alignment: Alignment.centerLeft,
            child: Text('Spin History', style: TextStyle(
              color: AppTheme.cyan, fontSize: 14, fontWeight: FontWeight.w700))),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: TournamentService.getSpinHistory(uid),
            builder: (_, snap) {
              final history = snap.data ?? [];
              if (history.isEmpty) return const Center(
                child: Text('Koi history nahi', style: TextStyle(color: AppTheme.textSec)));
              return Column(children: history.take(10).map((h) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(h['label'] ?? '', style: const TextStyle(color: AppTheme.textPri, fontWeight: FontWeight.w600)),
                  Text(_timeAgo(h['timestamp']), style: const TextStyle(color: AppTheme.textSec, fontSize: 12)),
                ]),
              )).toList());
            }),
        ],
        const SizedBox(height: 80),
      ]),
    );
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts as int);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Abhi';
  }
}

class _SpinPrize {
  final String label;
  final Color color;
  final String type;
  _SpinPrize(this.label, this.color, this.type);
}

class _WheelPainter extends CustomPainter {
  final List<_SpinPrize> prizes;
  _WheelPainter(this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radius = min(cx, cy);
    final segAngle = (2 * pi) / prizes.length;
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()..style = PaintingStyle.stroke
      ..color = AppTheme.bgDark ..strokeWidth = 2;

    for (int i = 0; i < prizes.length; i++) {
      final start = i * segAngle - pi / 2;
      paint.color = prizes[i].color;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        start, segAngle, true, paint);
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        start, segAngle, true, borderPaint);

      // Label
      final mid = start + segAngle / 2;
      final tx = cx + (radius * 0.65) * cos(mid);
      final ty = cy + (radius * 0.65) * sin(mid);
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(mid + pi / 2);
      final tp = TextPainter(
        text: TextSpan(text: prizes[i].label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center);
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Outer ring
    canvas.drawCircle(Offset(cx, cy), radius,
      Paint()..style = PaintingStyle.stroke ..color = AppTheme.border ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_) => false;
}

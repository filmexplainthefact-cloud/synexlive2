// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SPIN SCREEN
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/common_widgets.dart';

class SpinScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onUserUpdate;
  const SpinScreen({super.key, this.userData, this.onUserUpdate});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  List<Map<String, dynamic>> _prizes = [
    {'label': 'Better Luck', 'value': 0, 'prob': 35, 'color': 0xFF1b3c6e, 'type': 'nothing'},
    {'label': 'S\₹ 2', 'value': 2, 'prob': 22, 'color': 0xFF1565c0, 'type': 'cash'},
    {'label': 'S\₹ 5', 'value': 5, 'prob': 16, 'color': 0xFF7c4dff, 'type': 'cash'},
    {'label': 'S\₹ 10', 'value': 10, 'prob': 11, 'color': 0xFF00e5ff, 'type': 'cash'},
    {'label': 'S\₹ 25', 'value': 25, 'prob': 7, 'color': 0xFF00e676, 'type': 'cash'},
    {'label': 'S\₹ 50', 'value': 50, 'prob': 4, 'color': 0xFFffd700, 'type': 'cash'},
    {'label': 'Ticket', 'value': 1, 'prob': 3, 'color': 0xFFf50057, 'type': 'ticket'},
    {'label': 'S\₹ 100', 'value': 100, 'prob': 2, 'color': 0xFFff6d00, 'type': 'cash'},
  ];

  int _spinCost = 10;
  bool _spinning = false;
  Map<String, dynamic>? _lastResult;
  List<Map> _history = [];
  double _currentAngle = 0;
  int _synexPoints = 0;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this);
    _loadSettings();
    _loadHistory();
    _synexPoints = (widget.userData?['synexPoints'] ?? 0) as int;
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final s = await FirebaseService.getWheelSettings();
    if (s != null && mounted) {
      setState(() {
        if (s['cost'] != null) _spinCost = (s['cost'] as num).toInt();
        if (s['prizes'] != null) {
          _prizes = (s['prizes'] as List).map((p) => Map<String, dynamic>.from(p as Map)).toList();
        }
      });
    }
  }

  void _loadHistory() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    FirebaseService.spinHistoryStream(uid).listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      final data = event.snapshot.value as Map;
      final list = <Map>[];
      data.forEach((k, v) => list.add(Map<String, dynamic>.from(v as Map)));
      list.sort((a, b) => ((b['date'] ?? 0) as num).compareTo((a['date'] ?? 0) as num));
      if (mounted) setState(() => _history = list.take(10).toList());
    });
  }

  int _pickPrize() {
    final total = _prizes.fold<int>(0, (s, p) => s + (p['prob'] as int? ?? 1));
    final rand = math.Random().nextInt(total);
    int cum = 0;
    for (int i = 0; i < _prizes.length; i++) {
      cum += ((_prizes[i]['prob'] as int?) ?? 1);
      if (rand < cum) return i;
    }
    return 0;
  }

  Future<void> _doSpin() async {
    if (_spinning) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final bal = (widget.userData?['wallet'] ?? 0) as int;
    if (bal < _spinCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient balance! Add money first.',
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700))),
      );
      return;
    }

    setState(() => _spinning = true);
    final chosen = _pickPrize();
    final N = _prizes.length;
    final sliceAngle = (2 * math.pi) / N;
    final targetAngle = 5 * 2 * math.pi +
        (2 * math.pi - chosen * sliceAngle - sliceAngle / 2 - math.pi / 2);

    _spinCtrl.reset();
    _spinAnim = Tween<double>(begin: _currentAngle, end: _currentAngle + targetAngle).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut),
    );
    _spinCtrl.duration = const Duration(milliseconds: 4500);
    await _spinCtrl.forward();

    _currentAngle = (_currentAngle + targetAngle) % (2 * math.pi);

    // Award prize
    final prize = _prizes[chosen];
    final ptsEarned = prize['type'] == 'nothing' ? 5 : prize['type'] == 'ticket' ? 15 : math.max(5, ((prize['value'] as num) / 2).floor());
    final newPts = math.min(100, _synexPoints + ptsEarned);

    try {
      final db = FirebaseDatabase.instance.ref();
      final upd = <String, dynamic>{};
      int newBal = bal - _spinCost;
      upd['users/$uid/wallet'] = newBal;
      upd['users/$uid/synexPoints'] = newPts;
      final txKey = db.child('users/$uid/transactions').push().key;
      upd['users/$uid/transactions/$txKey'] = {
        'type': 'Spin Cost', 'amount': -_spinCost,
        'date': ServerValue.timestamp, 'status': 'completed', 'desc': 'Spin the Wheel',
      };
      if (prize['type'] == 'cash' && (prize['value'] as num) > 0) {
        newBal += (prize['value'] as num).toInt();
        upd['users/$uid/wallet'] = newBal;
        final wk = db.child('users/$uid/transactions').push().key;
        upd['users/$uid/transactions/$wk'] = {
          'type': 'Spin Win', 'amount': prize['value'],
          'date': ServerValue.timestamp, 'status': 'completed', 'desc': 'Wheel: ${prize['label']}',
        };
      } else if (prize['type'] == 'ticket') {
        upd['users/$uid/tickets'] = (widget.userData?['tickets'] ?? 0) + 1;
      }
      final hk = db.child('spinHistory/$uid').push().key;
      upd['spinHistory/$uid/$hk'] = {
        'label': prize['label'], 'type': prize['type'],
        'value': prize['value'], 'date': ServerValue.timestamp,
      };
      await db.update(upd);
      setState(() {
        _spinning = false;
        _lastResult = prize;
        _synexPoints = newPts;
      });
      widget.onUserUpdate?.call();
    } catch (e) {
      setState(() => _spinning = false);
    }
  }

  Future<void> _redeemPoints() async {
    if (_synexPoints < 100) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final db = FirebaseDatabase.instance.ref();
    await db.update({
      'users/$uid/synexPoints': 0,
      'users/$uid/tickets': (widget.userData?['tickets'] ?? 0) + 1,
    });
    setState(() => _synexPoints = 0);
    widget.onUserUpdate?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ðŸŽ« 1 Free Ticket redeemed!',
            style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg2,
        title: Text('Fortune Wheel', style: GoogleFonts.orbitron(
          fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.white,
        )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header card
            SynexCard(
              borderColor: AppColors.purple.withOpacity(0.4),
              glow: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ðŸŽ¡ Fortune Wheel',
                          style: GoogleFonts.orbitron(
                            fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white,
                          )),
                        const SizedBox(height: 2),
                        Text('Spin & Win Real Cash + Synex Points!',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12, color: AppColors.muted,
                          )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                    ),
                    child: Column(
                      children: [
                        Text('COST', style: GoogleFonts.rajdhani(
                          fontSize: 10, color: AppColors.muted, letterSpacing: 1,
                        )),
                        Text('â‚¹$_spinCost', style: GoogleFonts.orbitron(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Synex points bar
            SynexCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D47A1), AppColors.cyan],
                          ),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(color: AppColors.cyan.withOpacity(0.4), blurRadius: 8),
                          ],
                        ),
                        child: Center(
                          child: Text('S', style: GoogleFonts.orbitron(
                            fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white,
                          )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SYNEX POINTS',
                              style: GoogleFonts.orbitron(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppColors.cyan, letterSpacing: 0.5,
                              )),
                            Text('100 pts = 1 Free Ticket',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11, color: AppColors.muted,
                              )),
                          ],
                        ),
                      ),
                      Text('$_synexPoints / 100',
                        style: GoogleFonts.orbitron(
                          fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.cyan,
                        )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (_synexPoints / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.card2,
                      valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                      minHeight: 6,
                    ),
                  ),
                  if (_synexPoints >= 100) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _redeemPoints,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D47A1), AppColors.cyan],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: AppColors.cyan.withOpacity(0.3), blurRadius: 12),
                          ],
                        ),
                        child: Text('ðŸŽ« REDEEM FOR TICKET',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.orbitron(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 1,
                          )),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wheel
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // Glow ring
                Container(
                  width: 316, height: 316,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.4),
                        blurRadius: 30, spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                // Pointer
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      width: 0, height: 0,
                      decoration: const BoxDecoration(),
                      child: CustomPaint(
                        size: const Size(32, 36),
                        painter: _PointerPainter(),
                      ),
                    ),
                  ),
                ),
                // Canvas
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: AnimatedBuilder(
                    animation: _spinCtrl,
                    builder: (_, __) {
                      final angle = _spinCtrl.isAnimating
                          ? (_spinAnim.value)
                          : _currentAngle;
                      return CustomPaint(
                        size: const Size(300, 300),
                        painter: _WheelPainter(
                          prizes: _prizes,
                          angle: angle,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Spin button
            GestureDetector(
              onTap: _spinning ? null : _doSpin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 16),
                decoration: BoxDecoration(
                  gradient: _spinning
                      ? const LinearGradient(colors: [AppColors.card2, AppColors.card2])
                      : const LinearGradient(
                          colors: [Color(0xFF4A148C), AppColors.purple, Color(0xFF9C27B0)],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _spinning ? null : [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(0.5),
                      blurRadius: 20, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_spinning)
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.purple,
                        ),
                      )
                    else
                      const Icon(Icons.casino_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _spinning ? 'SPINNING...' : 'SPIN!',
                      style: GoogleFonts.orbitron(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: _spinning ? AppColors.muted : Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Result
            if (_lastResult != null)
              SynexCard(
                borderColor: AppColors.purple.withOpacity(0.5),
                glow: true,
                child: Column(
                  children: [
                    Text(
                      _lastResult!['type'] == 'nothing' ? 'ðŸ˜¢' :
                      _lastResult!['type'] == 'ticket' ? 'ðŸŽ«' : 'ðŸŽ‰',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastResult!['type'] == 'cash'
                          ? 'S\$ ${_lastResult!['value']} Cash!'
                          : _lastResult!['type'] == 'ticket'
                              ? 'ðŸŽ« Tournament Ticket!'
                              : 'Better Luck Next Time!',
                      style: GoogleFonts.orbitron(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastResult!['type'] == 'cash'
                          ? 'â‚¹${_lastResult!['value']} added to wallet!'
                          : _lastResult!['type'] == 'ticket'
                              ? '1 ticket added to account!'
                              : 'Synex Points earned! Try again.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13, color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // History
            if (_history.isNotEmpty) ...[
              const SectionHeader(title: 'SPIN HISTORY'),
              SynexCard(
                child: Column(
                  children: _history.asMap().entries.map((entry) {
                    final s = entry.value;
                    final isCash = s['type'] == 'cash' && (s['value'] as num?) != 0;
                    final isTicket = s['type'] == 'ticket';
                    final col = isCash ? AppColors.gold : isTicket ? AppColors.purple : AppColors.muted;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < _history.length - 1 ? 10 : 0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: col.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isTicket ? 'ðŸŽ«' : isCash ? 'ðŸ’°' : 'ðŸ˜¢',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isCash ? 'S\$ ${s['value']} Cash' : s['label'] ?? '',
                              style: GoogleFonts.rajdhani(
                                fontSize: 14, fontWeight: FontWeight.w700, color: col,
                              ),
                            ),
                          ),
                          Text(
                            _timeAgo(s['date']),
                            style: GoogleFonts.rajdhani(
                              fontSize: 11, color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt());
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

// â”€â”€ WHEEL PAINTER â”€â”€
class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;
  final double angle;

  const _WheelPainter({required this.prizes, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 4;
    final N = prizes.length;
    if (N == 0) return;
    final sliceAngle = (2 * math.pi) / N;

    // Draw outer ring shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), r + 4, shadowPaint);

    // Draw slices
    for (int i = 0; i < N; i++) {
      final p = prizes[i];
      final col = Color(p['color'] as int? ?? 0xFF1565c0);
      final start = angle + i * sliceAngle;

      // Gradient fill
      final gradPaint = Paint()
        ..shader = RadialGradient(
          colors: [col.withOpacity(0.5), col.withOpacity(0.9)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          start, sliceAngle, false,
        )
        ..close();
      canvas.drawPath(path, gradPaint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // Label
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(start + sliceAngle / 2);
      final midR = r * 0.62;

      final isCash = p['type'] == 'cash' && (p['value'] as num?) != 0;
      final isTicket = p['type'] == 'ticket';

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      if (isCash) {
        // S$ prefix
        textPainter.text = TextSpan(
          children: [
            TextSpan(
              text: 'S\$',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: N > 7 ? 7.0 : 8.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            TextSpan(
              text: '\n${p['value']}',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: N > 7 ? 8.0 : 10.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        );
      } else {
        textPainter.text = TextSpan(
          text: isTicket ? 'ðŸŽ«' : p['label'] as String? ?? '',
          style: TextStyle(
            fontSize: N > 7 ? 9.0 : 11.0,
            color: Colors.white.withOpacity(0.9),
            shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
          ),
        );
      }

      textPainter.layout(maxWidth: 60);
      textPainter.paint(
        canvas,
        Offset(midR - textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer ring
    final ringPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // Center circle
    final grad = RadialGradient(
      colors: [const Color(0xFF1565C0), const Color(0xFF030812)],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 22));
    canvas.drawCircle(Offset(cx, cy), 22, Paint()..shader = grad);
    final centerBorder = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 22, centerBorder);

    // S in center
    final stp = TextPainter(
      text: const TextSpan(
        text: 'S',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stp.paint(canvas, Offset(cx - stp.width / 2, cy - stp.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle || old.prizes != prizes;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.gold, Color(0xFFFFB300)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, 32, 36))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(16, 36)
      ..lineTo(0, 0)
      ..lineTo(32, 0)
      ..close();
    canvas.drawPath(path, paint);

    final glow = Paint()
      ..color = AppColors.gold.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(_PointerPainter _) => false;
}

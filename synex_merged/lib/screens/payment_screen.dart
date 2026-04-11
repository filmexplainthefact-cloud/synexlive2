import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _utrCtrl    = TextEditingController();
  int _step = 1; // 1=enter amount, 2=pay & enter UTR, 3=success
  bool _submitting = false;
  int _selectedAmount = 0;

  static const String _upiId = 'aqaskhan03@fam';
  static const String _upiName = 'Synex';

  static FirebaseDatabase get _db {
    try {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app('gaming'),
        databaseURL: 'https://k-upl-6a0db-default-rtdb.firebaseio.com',
      );
    } catch (_) {
      return FirebaseDatabase.instance;
    }
  }

  String get _qrUrl {
    final amount = _selectedAmount > 0 ? _selectedAmount : int.tryParse(_amountCtrl.text) ?? 0;
    final upiString = 'upi://pay?pa=$_upiId&pn=$_upiName&am=$amount&cu=INR&tn=SynexWallet';
    return 'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(upiString)}';
  }

  Future<void> _submitPayment() async {
    final amount = _selectedAmount > 0 ? _selectedAmount : int.tryParse(_amountCtrl.text) ?? 0;
    final utr = _utrCtrl.text.trim();

    if (amount < 10) {
      AppHelpers.showSnackBar(context, 'Minimum amount is Rs.10', isError: true);
      return;
    }
    if (utr.length < 10) {
      AppHelpers.showSnackBar(context, 'Enter valid UTR/Reference number (min 10 digits)', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final uid = fbAuth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      await _db.ref('paymentRequests/$uid/${DateTime.now().millisecondsSinceEpoch}').set({
        'uid': uid,
        'amount': amount,
        'utr': utr,
        'upiId': _upiId,
        'status': 'pending',
        'submittedAt': ServerValue.timestamp,
      });

      setState(() { _step = 3; _submitting = false; });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) AppHelpers.showSnackBar(context, 'Submission failed: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bg2,
      title: const Text('Add Money to Wallet'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
        onPressed: () => Navigator.pop(context)),
    ),
    body: SafeArea(
      child: _step == 1 ? _buildStep1() :
             _step == 2 ? _buildStep2() :
             _buildStep3(),
    ),
  );

  // Step 1 — Enter amount
  Widget _buildStep1() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Steps indicator
      _buildStepsBar(1),
      const SizedBox(height: 24),

      const Text('Select Amount', style: TextStyle(
        color: AppTheme.textPri, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),

      // Quick amount buttons
      Wrap(spacing: 10, runSpacing: 10, children: [50, 100, 200, 500, 1000, 2000].map((amt) =>
        GestureDetector(
          onTap: () { setState(() { _selectedAmount = amt; _amountCtrl.text = amt.toString(); }); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _selectedAmount == amt ? AppTheme.primary : AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedAmount == amt ? AppTheme.cyan : AppTheme.border)),
            child: Text('Rs.$amt', style: TextStyle(
              color: _selectedAmount == amt ? Colors.white : AppTheme.textPri,
              fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        )).toList()),
      const SizedBox(height: 20),

      // Custom amount
      const Text('Or enter custom amount',
        style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
      const SizedBox(height: 8),
      TextField(
        controller: _amountCtrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppTheme.textPri, fontSize: 16),
        onChanged: (v) => setState(() => _selectedAmount = 0),
        decoration: InputDecoration(
          hintText: 'Enter amount (min Rs.10)',
          hintStyle: const TextStyle(color: AppTheme.textHint),
          prefixText: 'Rs. ',
          prefixStyle: const TextStyle(color: AppTheme.textSec),
          filled: true, fillColor: AppTheme.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cyan)),
        ),
      ),
      const SizedBox(height: 32),

      // Info box
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.info_outline, color: AppTheme.cyan, size: 16),
            SizedBox(width: 6),
            Text('How it works', style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          SizedBox(height: 8),
          Text('1. Select or enter amount\n2. Pay via UPI QR code\n3. Enter UTR/Reference number\n4. Amount added after admin verification (few minutes)',
            style: TextStyle(color: AppTheme.textSec, fontSize: 12, height: 1.6)),
        ])),
      const SizedBox(height: 32),

      // Next button
      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: () {
            final amount = _selectedAmount > 0 ? _selectedAmount : int.tryParse(_amountCtrl.text) ?? 0;
            if (amount < 10) {
              AppHelpers.showSnackBar(context, 'Minimum amount is Rs.10', isError: true);
              return;
            }
            setState(() { _step = 2; if (_selectedAmount > 0) _amountCtrl.text = _selectedAmount.toString(); });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Proceed to Pay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)))),
    ]),
  );

  // Step 2 — QR + UTR
  Widget _buildStep2() {
    final amount = int.tryParse(_amountCtrl.text) ?? _selectedAmount;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        _buildStepsBar(2),
        const SizedBox(height: 24),

        // Amount display
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)]),
            borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            const Text('Pay Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Rs.$amount', style: const TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('UPI ID: $_upiId', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ])),
        const SizedBox(height: 20),

        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Image.network(
              _qrUrl, width: 220, height: 220,
              loadingBuilder: (_, child, progress) => progress == null ? child :
                const SizedBox(width: 220, height: 220,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
              errorBuilder: (_, __, ___) => Container(
                width: 220, height: 220,
                color: Colors.grey[100],
                child: const Center(child: Text('QR load failed.\nUse UPI ID below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13)))),
            ),
            const SizedBox(height: 8),
            Text('Scan with any UPI app', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
        const SizedBox(height: 12),

        // Copy UPI ID
        GestureDetector(
          onTap: () {
            Clipboard.setData(const ClipboardData(text: _upiId));
            AppHelpers.showSnackBar(context, 'UPI ID copied!');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.card, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text(_upiId, style: TextStyle(color: AppTheme.textPri, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Icon(Icons.copy_rounded, color: AppTheme.textSec, size: 16),
            ]))),
        const SizedBox(height: 24),

        // UTR input
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Enter UTR / Reference Number *',
            style: TextStyle(color: AppTheme.textSec, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Find UTR in your UPI app payment history',
            style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
          const SizedBox(height: 8),
          TextField(
            controller: _utrCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPri, fontSize: 15, letterSpacing: 1),
            decoration: InputDecoration(
              hintText: 'e.g. 123456789012',
              hintStyle: const TextStyle(color: AppTheme.textHint),
              prefixIcon: const Icon(Icons.receipt_long, color: AppTheme.textSec, size: 18),
              filled: true, fillColor: AppTheme.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cyan)),
            )),
        ]),
        const SizedBox(height: 24),

        // Submit
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _submitting
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Submit for Verification',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)))),

        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Back', style: TextStyle(color: AppTheme.textSec))),
      ]),
    );
  }

  // Step 3 — Success
  Widget _buildStep3() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48)),
        const SizedBox(height: 24),
        const Text('Request Submitted!', style: TextStyle(
          color: AppTheme.textPri, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text('Your payment is under review.\nAmount will be added to your wallet within a few minutes after admin verification.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSec, fontSize: 14, height: 1.6)),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Back to Profile',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)))),
      ]),
    ));

  Widget _buildStepsBar(int current) => Row(children: [1, 2, 3].map((step) {
    final done = step < current;
    final active = step == current;
    return Expanded(child: Row(children: [
      Expanded(child: Container(height: 3,
        color: done || active ? AppTheme.primary : AppTheme.border)),
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: done ? AppTheme.success : active ? AppTheme.primary : AppTheme.card,
          shape: BoxShape.circle,
          border: Border.all(color: done ? AppTheme.success : active ? AppTheme.primary : AppTheme.border)),
        child: Center(child: done
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : Text('$step', style: TextStyle(
              color: active ? Colors.white : AppTheme.textSec,
              fontSize: 11, fontWeight: FontWeight.w700)))),
      if (step < 3) Expanded(child: Container(height: 3,
        color: done ? AppTheme.primary : AppTheme.border)),
    ]));
  }).toList());
}

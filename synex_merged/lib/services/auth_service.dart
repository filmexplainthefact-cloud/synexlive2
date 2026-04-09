import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthService extends ChangeNotifier {
  final _auth   = FirebaseAuth.instance;
  final _db     = FirebaseFirestore.instance;
  final _google = GoogleSignIn();

  UserModel? _user;
  bool _loading = false;

  UserModel? get currentUser   => _user;
  bool get isLoading           => _loading;
  bool get isLoggedIn          => _auth.currentUser != null;
  String? get currentUserId    => _auth.currentUser?.uid;

  AuthService() { _auth.authStateChanges().listen(_onAuth); }

  Future<void> _onAuth(User? u) async {
    if (u != null) await _fetch(u.uid); else _user = null;
    notifyListeners();
  }

  Future<void> _fetch(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) _user = UserModel.fromFirestore(doc);
    } catch (e) { debugPrint('fetch error: $e'); }
  }

  Future<String?> signUpWithEmail({required String name, required String email, required String password}) async {
    try {
      _loading = true; notifyListeners();
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name.trim());
      final u = UserModel(uid: cred.user!.uid, name: name.trim(), email: email.trim(), createdAt: DateTime.now());
      await _db.collection(AppConstants.usersCollection).doc(u.uid).set(u.toFirestore());
      _user = u;
      return null;
    } on FirebaseAuthException catch (e) { return _errMsg(e.code);
    } catch (_) { return AppConstants.errorGeneric;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<String?> signInWithEmail({required String email, required String password}) async {
    try {
      _loading = true; notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) { return _errMsg(e.code);
    } catch (_) { return AppConstants.errorGeneric;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _loading = true; notifyListeners();
      final gUser = await _google.signIn();
      if (gUser == null) return 'Sign in cancel hua';
      final gAuth = await gUser.authentication;
      final cred  = GoogleAuthProvider.credential(accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      final uc    = await _auth.signInWithCredential(cred);
      if (uc.additionalUserInfo?.isNewUser ?? false) {
        final u = UserModel(uid: uc.user!.uid, name: uc.user!.displayName ?? 'User',
          email: uc.user!.email ?? '', photoUrl: uc.user!.photoURL, createdAt: DateTime.now());
        await _db.collection(AppConstants.usersCollection).doc(u.uid).set(u.toFirestore());
        _user = u;
      } else { await _fetch(uc.user!.uid); }
      return null;
    } catch (e) { return 'Google sign in fail: $e';
    } finally { _loading = false; notifyListeners(); }
  }

  Future<void> signOut() async {
    await _google.signOut(); await _auth.signOut();
    _user = null; notifyListeners();
  }

  Future<String?> updateProfile({String? name, String? bio, String? photoUrl,
    String? ign, String? squadName, String? freefireUid}) async {
    try {
      final uid = currentUserId; if (uid == null) return 'Login nahi hai';
      final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (ign != null) updates['ign'] = ign;
      if (squadName != null) updates['squadName'] = squadName;
      if (freefireUid != null) updates['freefireUid'] = freefireUid;
      await _db.collection(AppConstants.usersCollection).doc(uid).update(updates);
      await _fetch(uid); notifyListeners(); return null;
    } catch (_) { return AppConstants.errorGeneric; }
  }

  String _errMsg(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email already registered hai.';
      case 'invalid-email':        return 'Valid email daalo.';
      case 'weak-password':        return 'Password weak hai (min 6 chars).';
      case 'user-not-found':       return 'Account nahi mila.';
      case 'wrong-password':       return 'Password galat hai.';
      case 'too-many-requests':    return 'Bahut attempts. Baad mein try karo.';
      default:                     return AppConstants.errorGeneric;
    }
  }
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;
  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onVerified,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(String, int?) onCodeSent,
    required void Function(String) onAutoRetrievalTimeout,
  }) async {
    final PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential credential) {
      onVerified(credential);
    };

    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException e) {
      onFailed(e);
    };

    final PhoneCodeSent codeSent = (String verId, int? token) {
      _verificationId = verId;
      _resendToken = token;
      onCodeSent(verId, token);
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verId) {
      _verificationId = verId;
      onAutoRetrievalTimeout(verId);
    };

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: _resendToken,
    );
  }

  Future<UserCredential> signInWithSmsCode({
    required String smsCode,
    String? verificationId,
  }) async {
    final verId = verificationId ?? _verificationId;
    if (verId == null) {
      throw FirebaseAuthException(
          code: 'no-verification-id', message: 'Verification ID is null.');
    }
    final credential =
        PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    final result = await _auth.signInWithCredential(credential);
    notifyListeners();
    return result;
  }

  Future<UserCredential?> linkAnonymousWithCredential(PhoneAuthCredential credential) async {
    if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
      return await _auth.currentUser!.linkWithCredential(credential);
    }
    return null;
  }
}

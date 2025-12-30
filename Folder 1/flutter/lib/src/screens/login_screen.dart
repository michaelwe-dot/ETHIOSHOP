import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+2519');
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startPhoneVerification() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final phone = _phoneController.text.trim();
    setState(() => _loading = true);

    await auth.verifyPhone(
      phoneNumber: phone,
      onVerified: (credential) async {
        await auth.signInWithSmsCode(smsCode: credential.smsCode ?? '', verificationId: credential.verificationId);
        setState(() => _loading = false);
        final user = auth.currentUser;
        if (user != null) await PushService.saveUserDeviceToken(user.uid);
        Navigator.pushReplacementNamed(context, '/home');
      },
      onFailed: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth failed: ${e.message}')));
      },
      onCodeSent: (verId, token) {
        setState(() {
          _codeSent = true;
          _verificationId = verId;
          _loading = false;
        });
      },
      onAutoRetrievalTimeout: (verId) {
        setState(() {
          _verificationId = verId;
          _loading = false;
        });
      },
    );
  }

  void _submitSmsCode() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final code = _codeController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the 4-6 digit code')));
      return;
    }
    setState(() => _loading = true);
    try {
      await auth.signInWithSmsCode(smsCode: code, verificationId: _verificationId);
      final user = auth.currentUser;
      if (user != null) await PushService.saveUserDeviceToken(user.uid);
      Navigator.pushReplacementNamed(context, '/home');
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code verify failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in — ETHIO🛍')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (e.g. +2519XXXXXXXX)'),
            ),
            const SizedBox(height: 12),
            _codeSent
                ? Column(
                    children: [
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Enter OTP'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loading ? null : _submitSmsCode,
                        child: _loading ? const CircularProgressIndicator() : const Text('Verify Code'),
                      ),
                      TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() => _codeSent = false);
                                },
                          child: const Text('Use different number')),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _loading ? null : _startPhoneVerification,
                    child: _loading ? const CircularProgressIndicator() : const Text('Send OTP'),
                  ),
            const SizedBox(height: 20),
            const Text('Need help? ☎️ 0942303002'),
          ],
        ),
      ),
    );
  }
}

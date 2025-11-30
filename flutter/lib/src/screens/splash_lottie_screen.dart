import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LottieSplashScreen extends StatefulWidget {
  const LottieSplashScreen({super.key});
  @override
  State<LottieSplashScreen> createState() => _LottieSplashScreenState();
}

class _LottieSplashScreenState extends State<LottieSplashScreen> {
  bool _offline = false;
  bool _checking = true;
  late StreamSubscription _connSub;

  @override
  void initState() {
    super.initState();
    _runStartup();
    _connSub = Connectivity().onConnectivityChanged.listen((_) {});
  }

  @override
  void dispose() {
    _connSub.cancel();
    super.dispose();
  }

  Future<bool> _checkNetwork() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
    } catch (_) {
      return false;
    }
  }

  Future<void> _runStartup() async {
    final ok = await _checkNetwork();
    if (!ok) {
      setState(() {
        _offline = true;
        _checking = false;
      });
      _showNoNetworkDialog();
      return;
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showNoNetworkDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('No network connection', style: Theme.of(context).textTheme.headline6),
            const SizedBox(height: 8),
            const Text('☎️ 0942303002\n📧 Ethiopianmark8@gmail.com', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _checking = true;
                  });
                  _runStartup();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ])
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Lottie.asset('assets/lottie/ethio_splash.json', width: 220, repeat: false),
          const SizedBox(height: 12),
          const SizedBox(
            width: 180,
            child: LinearProgressIndicator(),
          ),
          const SizedBox(height: 8),
          const Text('0941090959', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }
}

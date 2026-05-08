import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:dinoshare/pages/home.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/util/platform_asset.dart';
import 'package:dinoshare/widgets/button.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  bool _storageGranted = false;
  bool _notificationGranted = false;
  bool _requesting = false;
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    if (!Platform.isAndroid) {
      setState(() {
        _storageGranted = true;
        _notificationGranted = true;
      });
      return;
    }
    final storage = await Permission.manageExternalStorage.status;
    final notif = await Permission.notification.status;
    setState(() {
      _storageGranted = storage.isGranted;
      _notificationGranted = notif.isGranted;
    });
  }

  bool get _allGranted {
    if (!Platform.isAndroid) return true;
    return _storageGranted && _notificationGranted;
  }

  bool get _showLetsGo => _allGranted || _permissionsRequested;

  Future<void> _requestPermissions() async {
    if (_requesting || !Platform.isAndroid) return;
    setState(() => _requesting = true);
    try {
      await Permission.manageExternalStorage.request();
      await Permission.notification.request();
    } catch (_) {}
    await _initPermissions();
    if (mounted) {
      setState(() {
        _requesting = false;
        _permissionsRequested = true;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    await completeOnboarding();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(CupertinoPageRoute(builder: (_) => const Home()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      color: theme.colors.background,
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 40,
              children: [
                Column(
                  spacing: 16,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image(
                        image: AssetImage(platformAsset('app_icon.png')),
                        width: 64,
                        height: 64,
                      ),
                    ),
                    Text(
                      'DinoShare',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: theme.colors.foreground,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  _allGranted
                      ? 'All set to go.'
                      : 'Provide some permission\nto run this app smoothly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: theme.colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              spacing: 12,
              children: [
                if (!_allGranted)
                  Row(
                    children: [
                      Expanded(
                        child: DButton(
                          variant: DButtonVariant.primary,
                          disabled: _requesting,
                          onPressed: _requestPermissions,
                          child: const Text('Enable Permissions'),
                        ),
                      ),
                    ],
                  ),
                if (_showLetsGo)
                  Row(
                    children: [
                      Expanded(
                        child: DButton(
                          variant: DButtonVariant.success,
                          onPressed: _completeOnboarding,
                          child: const Text("Let's go"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

part of 'state_index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings: load, save, helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<String> getDefaultDeviceName() async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) return (await info.androidInfo).model;
    if (Platform.isIOS) return (await info.iosInfo).name;
    if (Platform.isMacOS) return (await info.macOsInfo).computerName;
    if (Platform.isWindows) return (await info.windowsInfo).computerName;
    if (Platform.isLinux) return (await info.linuxInfo).name;
  } catch (_) {}
  return 'LAFs Device';
}

Future<String> _getDeviceTypeLabel() async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final d = await info.androidInfo;
      // Very rough tablet heuristic: tablets often have "tab" in the model.
      if (d.model.toLowerCase().contains('tab')) return 'Android Tablet';
      return 'Android';
    }
    if (Platform.isIOS) {
      final d = await info.iosInfo;
      if (d.model.toLowerCase().contains('ipad')) return 'iPad';
      return 'iPhone';
    }
    if (Platform.isMacOS) {
      final d = await info.macOsInfo;
      return _parseMacModel(d.model);
    }
    if (Platform.isWindows) return 'Windows PC';
    if (Platform.isLinux) return 'Linux PC';
  } catch (_) {}
  return 'Device';
}

String _parseMacModel(String identifier) {
  final m = identifier.toLowerCase().replaceAll(' ', '');
  if (m.contains('macbookpro')) return 'MacBook Pro';
  if (m.contains('macbookair')) return 'MacBook Air';
  if (m.contains('macbook')) return 'MacBook';
  if (m.contains('macpro')) return 'Mac Pro';
  if (m.contains('macmini')) return 'Mac mini';
  if (m.contains('macstudio')) return 'Mac Studio';
  if (m.contains('imac')) return 'iMac';
  return 'Mac';
}

Future<void> loadAppSettings() async {
  await transferService.initialize();
  final prefs = await SharedPreferences.getInstance();

  // ── Receive path ──────────────────────────────────────────────────────────
  var savedPath = prefs.getString(_kReceivePath);
  // Clear any stale macOS sandboxed-container or old LAFs-subfolder paths.
  if (Platform.isMacOS && savedPath != null) {
    if (savedPath.contains('/Library/Containers/') ||
        savedPath.endsWith('/Dino') ||
        savedPath.endsWith('/dinoshare-downloads')) {
      savedPath = null;
      await prefs.remove(_kReceivePath);
    }
  }
  final defaultPath = await transferService.defaultReceiveDirectory();
  appReceivePath.value = savedPath ?? defaultPath;
  await transferService.setReceiveBasePath(appReceivePath.value);

  // ── Device name & type ────────────────────────────────────────────────────
  final savedName = prefs.getString(_kDeviceName);
  if (savedName == null || savedName.isEmpty) {
    final detected = await getDefaultDeviceName();
    appDeviceName.value = detected;
    await prefs.setString(_kDeviceName, detected);
  } else {
    appDeviceName.value = savedName;
  }
  appDeviceTypeLabel.value = await _getDeviceTypeLabel();

  // ── Data unit type ────────────────────────────────────────────────────────
  final savedUnit = prefs.getString(_kDataUnit);
  if (savedUnit != null) {
    appDataUnit.value = DataUnitType.fromLabel(savedUnit);
  }

  // ── Always receive ────────────────────────────────────────────────────────
  final savedAlwaysReceive = prefs.getBool(_kAlwaysReceive);
  appAlwaysReceive.value = savedAlwaysReceive ?? false;

  // ── Full power mode ───────────────────────────────────────────────────────
  final savedFullPower = prefs.getBool(_kFullPower);
  appFullPowerMode.value = savedFullPower ?? false;
  transferService.setFullPowerMode(appFullPowerMode.value);

  // ── Notifications ──────────────────────────────────────────────────────────
  final savedNotifications = prefs.getBool(_kNotificationsEnabled);
  appNotificationsEnabled.value = savedNotifications ?? true;
  transferService.notificationsEnabled = appNotificationsEnabled.value;

  // ── Onboarding ────────────────────────────────────────────────────────────
  appOnboardingDone = prefs.getBool(_kOnboardingDone) ?? false;

  // ── History ───────────────────────────────────────────────────────────────
  await _loadTransferHistory();

  // ── Favourite devices ───────────────────────────────────────────────────
  await _loadFavouriteDevices();

  // ── Wire transfer-complete callback ──────────────────────────────────────
  transferService.onTransferComplete = (session) {
    addTransferToHistory(session);
  };

  // ── Start receiver if always-receive is on ───────────────────────────────
  if (appAlwaysReceive.value) {
    await transferService.startReceiver(deviceName: appDeviceName.value);
  }
}

Future<void> setReceivePath(String? path) async {
  final prefs = await SharedPreferences.getInstance();
  if (path == null || path.trim().isEmpty) {
    await prefs.remove(_kReceivePath);
    appReceivePath.value = await transferService.defaultReceiveDirectory();
  } else {
    final norm = path.trim();
    await prefs.setString(_kReceivePath, norm);
    appReceivePath.value = norm;
  }
  await transferService.setReceiveBasePath(appReceivePath.value);
}

Future<void> setDeviceName(String name) async {
  final trimmed = name.trim();
  final value = trimmed.isEmpty ? 'LAFs Device' : trimmed;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kDeviceName, value);
  appDeviceName.value = value;
}

Future<void> setDataUnit(DataUnitType unit) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kDataUnit, unit.label);
  appDataUnit.value = unit;
}

Future<void> setAlwaysReceive(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kAlwaysReceive, enabled);
  appAlwaysReceive.value = enabled;
  if (enabled) {
    await transferService.startReceiver(deviceName: appDeviceName.value);
  } else {
    await transferService.stopReceiver();
  }
}

Future<void> setFullPowerMode(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kFullPower, enabled);
  appFullPowerMode.value = enabled;
  transferService.setFullPowerMode(enabled);
}

Future<void> setNotificationsEnabled(bool enabled) async {
  if (enabled) {
    final granted = await transferService.requestNotificationPermission();
    if (!granted) {
      if (Platform.isMacOS) {
        await launchUrl(
          Uri.parse(
            'x-apple.systempreferences:com.apple.Notifications-Settings',
          ),
        );
      } else if (Platform.isIOS) {
        await launchUrl(Uri.parse('app-settings:'));
      }
      return;
    }
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kNotificationsEnabled, enabled);
  appNotificationsEnabled.value = enabled;
  transferService.notificationsEnabled = enabled;
  await transferService.showStatusNotification(
    title: 'Notifications',
    body:
        enabled
            ? 'Notifications are turned on.'
            : 'Notifications are turned off.',
  );
}

Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
  appOnboardingDone = true;
}

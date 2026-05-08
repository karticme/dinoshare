part of 'state_index.dart';

// ── Global keys ──────────────────────────────────────────────────────────────
const String _kReceivePath = 'receive_path';
const String _kDeviceName = 'device_name';
const String _kTransferHistory = 'transfer_history';
const String _kFavouriteDevices = 'favourite_devices';
const String _kDataUnit = 'data_unit';
const String _kAlwaysReceive = 'always_receive';
const String _kFullPower = 'full_power';
const String _kOnboardingDone = 'onboarding_done';
const String _kNotificationsEnabled = 'notifications_enabled';

// ── Global ValueNotifiers ────────────────────────────────────────────────────

/// Current app theme mode (persisted by AppThemeController in theme.dart).
final ValueNotifier<String> appDeviceName = ValueNotifier('LAFs Device');
final ValueNotifier<String> appDeviceTypeLabel = ValueNotifier('Device');
final ValueNotifier<String?> appReceivePath = ValueNotifier(null);
final ValueNotifier<DataUnitType> appDataUnit = ValueNotifier(
  DataUnitType.bytes,
);
final ValueNotifier<bool> appAlwaysReceive = ValueNotifier(false);
final ValueNotifier<bool> appFullPowerMode = ValueNotifier(false);
final ValueNotifier<bool> appNotificationsEnabled = ValueNotifier(true);
final ValueNotifier<List<SelectedShareItem>> appShareItems = ValueNotifier(
  <SelectedShareItem>[],
);
final ValueNotifier<List<FavouriteDevice>> appFavouriteDevices = ValueNotifier(
  <FavouriteDevice>[],
);
final ValueNotifier<List<TransferHistoryItem>> appTransferHistory =
    ValueNotifier(<TransferHistoryItem>[]);

/// Set to true after the user completes onboarding.
bool appOnboardingDone = false;

/// Singleton service reference.
final DinoshareTransferService transferService =
    DinoshareTransferService.instance;

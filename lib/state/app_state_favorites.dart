part of 'state_index.dart';

Future<void> _loadFavouriteDevices() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kFavouriteDevices);
  if (raw == null || raw.isEmpty) {
    appFavouriteDevices.value = [];
    return;
  }
  try {
    final list = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(FavouriteDevice.fromJson)
        .where((device) => device.id.trim().isNotEmpty)
        .toList();
    appFavouriteDevices.value = list;
  } catch (_) {
    appFavouriteDevices.value = [];
  }
}

bool isFavouriteDevice(String id) {
  final normalizedId = id.trim();
  if (normalizedId.isEmpty) return false;
  return appFavouriteDevices.value.any((device) => device.id == normalizedId);
}

Future<void> addFavouriteDevice(FavouriteDevice device) async {
  final id = device.id.trim();
  if (id.isEmpty) return;

  final current = List<FavouriteDevice>.from(appFavouriteDevices.value);
  current.removeWhere((item) => item.id == id);
  current.insert(
    0,
    device.copyWith(name: device.name, deviceType: device.deviceType),
  );
  appFavouriteDevices.value = current;
  await _saveFavouriteDevices();
}

Future<void> removeFavouriteDevice(String id) async {
  final current =
      appFavouriteDevices.value.where((device) => device.id != id).toList();
  appFavouriteDevices.value = current;
  await _saveFavouriteDevices();
}

Future<void> _saveFavouriteDevices() async {
  final prefs = await SharedPreferences.getInstance();
  final json = jsonEncode(
    appFavouriteDevices.value.map((device) => device.toJson()).toList(),
  );
  await prefs.setString(_kFavouriteDevices, json);
}

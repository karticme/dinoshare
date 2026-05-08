part of 'transfer_service.dart';

String _getDeviceTypeString() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

class DinoshareTransferService {
  DinoshareTransferService._();
  static final DinoshareTransferService instance = DinoshareTransferService._();

  static const String _kDeviceId = 'device_id';

  // ── Public observables ───────────────────────────────────────────────────
  final ValueNotifier<List<PeerDevice>> discoveredPeers = ValueNotifier(
    <PeerDevice>[],
  );
  final ValueNotifier<IncomingTransferRequest?> incomingRequest = ValueNotifier(
    null,
  );
  final ValueNotifier<TransferSession?> activeSession = ValueNotifier(null);

  void Function(TransferSession)? onTransferComplete;

  // ── Runtime settings ─────────────────────────────────────────────────────
  bool _fullPowerMode = false;
  String _deviceName = 'Dino Device';
  String _deviceId = '';
  String _receiveBasePath = '';

  void setFullPowerMode(bool enabled) => _fullPowerMode = enabled;

  // ── Computed constants based on power mode ───────────────────────────────
  int get _socketBuffer =>
      _fullPowerMode ? _kPowerSocketBuffer : _kNormalSocketBuffer;
  int get _parallelConns =>
      _fullPowerMode ? _kPowerParallelConns : _kNormalParallelConns;
  int get _largeFileThreshold =>
      _fullPowerMode ? _kPowerLargeFileThreshold : _kNormalLargeFileThreshold;
  int get _parallelChunkSize =>
      _fullPowerMode ? _kPowerParallelChunkSize : _kNormalParallelChunkSize;
  // ── Internal state ───────────────────────────────────────────────────────
  final Map<String, PeerDevice> _peerMap = {};
  final Set<Socket> _activeSockets = {};
  final Set<InternetAddress> _discoveryTargets = {};
  final Map<String, _PendingIncoming> _pendingIncoming = {};
  final Map<String, Set<int>> _chunkedFileProgress = {};

  RawDatagramSocket? _discoverySocket;
  ServerSocket? _controlServer;
  Timer? _discoverTimer;
  Timer? _peerPruneTimer;
  Timer? _speedTimer;
  Timer? _etaTimer;

  BonsoirBroadcast? _bonjourBroadcast;
  BonsoirDiscovery? _bonjourDiscovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _bonjourDiscoverySub;
  final Set<String> _bonjourPeerIds = {};

  bool _initialized = false;
  bool _discovering = false;
  bool _receivingEnabled = false;
  bool _multicastJoined = false;
  bool _localStopRequested = false;

  int _controlPort = 0;

  // Speed tracking
  DateTime _lastSpeedSampleAt = DateTime.now();
  int _lastSpeedBytes = 0;

  // Per-session crypto
  _SessionCrypto? _sessionCrypto;
  SecretKey? _sessionKey;

  // Per-session peer endpoint (so we can signal stop even after sockets die).
  InternetAddress? _peerAddress;
  int? _peerControlPort;

  // Progress helpers
  String? _currentTopLevelName;
  int _topLevelStartBytes = 0;
  List<TransferFileEntry> _currentTransferFiles = [];

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ─────────────────────────────────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _deviceId = await _loadOrCreateDeviceId();
    _receiveBasePath = await defaultReceiveDirectory();
    _controlPort = await _pickFreePort();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    if (Platform.isIOS || Platform.isMacOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<int> _pickFreePort() async {
    final rng = Random.secure();
    for (var i = 0; i < 30; i++) {
      final port = 44001 + rng.nextInt(3998);
      try {
        final s = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
          shared: false,
        );
        await s.close();
        return port;
      } catch (_) {}
    }
    final s = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final port = s.port;
    await s.close();
    return port;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Default receive directory
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> defaultReceiveDirectory() async {
    Future<String> ensureDir(String path) async {
      final dir = Directory(path);
      if (!dir.existsSync()) await dir.create(recursive: true);
      return path;
    }

    if (Platform.isAndroid) {
      try {
        return await ensureDir('/storage/emulated/0/Download/Dino');
      } catch (_) {
        final appDir = await getExternalStorageDirectory();
        return await ensureDir(p.join(appDir?.path ?? '/tmp', 'Dino'));
      }
    }
    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      return await ensureDir(p.join(docs.path, 'Dino Received'));
    }
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (home.isNotEmpty) {
      return await ensureDir(p.join(home, 'Downloads', 'Dino'));
    }
    return await ensureDir(
      p.join(Directory.systemTemp.path, 'dinoshare-downloads'),
    );
  }

  Future<void> setReceiveBasePath(String? customPath) async {
    _receiveBasePath =
        (customPath?.trim().isNotEmpty == true)
            ? customPath!.trim()
            : await defaultReceiveDirectory();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stop
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> stopActiveTransfer() async {
    final session = activeSession.value;
    if (session == null) return;
    _localStopRequested = true;
    await _sendStopSignal(session);
    for (final s in _activeSockets) {
      s.destroy();
    }
    _activeSockets.clear();
    _finishSession(status: TransferStatus.stopped, error: 'Stopped by you');
    await _notifyStopped(activeSession.value);
  }

  Future<void> _sendStopSignal(TransferSession session) async {
    final addr =
        _peerAddress ??
        (_activeSockets.isNotEmpty ? _activeSockets.first.remoteAddress : null);
    final port = _peerControlPort;
    if (addr == null || port == null || port == 0) return;
    try {
      final s = await Socket.connect(
        addr,
        port,
        timeout: const Duration(milliseconds: 700),
      );
      try {
        s.add(
          utf8.encode(
            '${jsonEncode({'type': 'transfer_stop', 'sessionId': session.sessionId, 'by': session.role == TransferRole.sending ? 'sender' : 'receiver'})}\n',
          ),
        );
        await s.flush();
      } finally {
        await s.close();
      }
    } catch (_) {}
  }

  void clearCompletedSession() {
    final s = activeSession.value;
    if (s == null) return;
    if (s.status == TransferStatus.completed ||
        s.status == TransferStatus.rejected ||
        s.status == TransferStatus.failed ||
        s.status == TransferStatus.stopped) {
      activeSession.value = null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Speed & ETA timers (raw, no smoothing)
  // ─────────────────────────────────────────────────────────────────────────

  void _resetSpeedCounters() {
    _lastSpeedSampleAt = DateTime.now();
    _lastSpeedBytes = activeSession.value?.bytesTransferred ?? 0;
  }

  void _startSpeedTimer() {
    _speedTimer?.cancel();
    _etaTimer?.cancel();

    _speedTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final session = activeSession.value;
      if (session == null || session.status != TransferStatus.inProgress) {
        return;
      }
      final now = DateTime.now();
      final elapsed =
          now.difference(_lastSpeedSampleAt).inMilliseconds / 1000.0;
      if (elapsed <= 0) return;
      final delta = (session.bytesTransferred - _lastSpeedBytes).clamp(
        0,
        1 << 60,
      );
      final speed = delta / elapsed;
      final peak = max(session.peakSpeedBytesPerSec, speed);
      activeSession.value = session.copyWith(
        currentSpeedBytesPerSec: speed,
        peakSpeedBytesPerSec: peak,
      );
      _lastSpeedSampleAt = now;
      _lastSpeedBytes = session.bytesTransferred;
    });

    _etaTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final session = activeSession.value;
      if (session == null || session.status != TransferStatus.inProgress) {
        return;
      }
      final remaining = session.totalBytes - session.bytesTransferred;
      if (remaining <= 0) {
        activeSession.value = session.copyWith(estimatedSecondsRemaining: 0);
        return;
      }
      final elapsedSec = max(
        1,
        DateTime.now().difference(session.startedAt).inSeconds,
      );
      final avgSpeed = session.bytesTransferred / elapsedSec;
      final effectiveSpeed =
          session.currentSpeedBytesPerSec > 0
              ? session.currentSpeedBytesPerSec * 0.7 + avgSpeed * 0.3
              : avgSpeed;
      if (effectiveSpeed < 10 * 1024) {
        activeSession.value = session.copyWith(clearEta: true);
        return;
      }
      final etaSec = max(1, (remaining / effectiveSpeed).ceil());
      activeSession.value = session.copyWith(estimatedSecondsRemaining: etaSec);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Session state helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _onBytesMoved(int bytes) {
    final session = activeSession.value;
    if (session == null) return;
    final next = min(session.totalBytes, session.bytesTransferred + bytes);
    List<TransferItemProgress>? updatedItems;
    if (_currentTopLevelName != null) {
      final itemBytes = next - _topLevelStartBytes;
      updatedItems =
          session.allItems.map((item) {
            if (item.name == _currentTopLevelName) {
              return item.copyWith(bytesTransferred: itemBytes);
            }
            return item;
          }).toList();
    }
    activeSession.value = session.copyWith(
      bytesTransferred: next,
      allItems: updatedItems,
    );
  }

  void _setSessionStatus(TransferStatus status) {
    final s = activeSession.value;
    if (s == null) return;
    activeSession.value = s.copyWith(status: status);
  }

  void _setCurrentFile(String? name) {
    final session = activeSession.value;
    if (session == null) return;
    if (name != null) {
      for (final f in _currentTransferFiles) {
        if (f.name == name) {
          _currentTopLevelName = f.topLevelName;
          _topLevelStartBytes = session.bytesTransferred;
          break;
        }
      }
    }
    activeSession.value = session.copyWith(currentFile: name);
  }

  void _appendCompleted(TransferCompletedItem item) {
    final session = activeSession.value;
    if (session == null) return;
    final updatedAll =
        session.allItems.map((fi) {
          if (fi.name == item.topLevelName || fi.name == item.name) {
            return fi.copyWith(bytesTransferred: fi.sizeBytes, path: item.path);
          }
          return fi;
        }).toList();
    activeSession.value = session.copyWith(
      completedItems: [...session.completedItems, item],
      allItems: updatedAll,
    );
  }

  void _finishSession({required TransferStatus status, String? error}) {
    _speedTimer?.cancel();
    _etaTimer?.cancel();
    _speedTimer = null;
    _etaTimer = null;
    final s = activeSession.value;
    if (s == null) {
      _sessionKey = null;
      _sessionCrypto = null;
      _peerAddress = null;
      _peerControlPort = null;
      return;
    }
    final wasInProgressOrRequesting =
        s.status == TransferStatus.inProgress ||
        s.status == TransferStatus.requesting;
    activeSession.value = s.copyWith(
      status: status,
      currentSpeedBytesPerSec: 0,
      endedAt: DateTime.now(),
      error: error,
    );
    final shouldNotifyPeer =
        wasInProgressOrRequesting &&
        !_localStopRequested &&
        (status == TransferStatus.failed || status == TransferStatus.stopped);
    if (shouldNotifyPeer) {
      unawaited(_sendStopSignal(activeSession.value!));
    }
    _sessionKey = null;
    _sessionCrypto = null;
    _peerAddress = null;
    _peerControlPort = null;
    if (status == TransferStatus.completed) {
      final completed = activeSession.value;
      if (completed != null) onTransferComplete?.call(completed);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notifications
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _notifyComplete(TransferSession? session) async {
    if (session == null) return;
    await _showNotification(
      title: 'Transfer completed',
      body: '${session.topLevelCount} item(s) with ${session.peerName}',
    );
  }

  Future<void> _notifyStopped(TransferSession? session) async {
    if (session == null) return;
    final action =
        session.role == TransferRole.sending ? 'Sharing' : 'Receiving';
    await _showNotification(
      title: '$action stopped',
      body: session.error ?? '$action was stopped.',
    );
  }

  Future<void> _notifyFailed(TransferSession? session) async {
    if (session == null) return;
    final action =
        session.role == TransferRole.sending ? 'Sharing' : 'Receiving';
    await _showNotification(
      title: '$action failed',
      body: session.error ?? 'Transfer could not complete.',
    );
  }

  bool notificationsEnabled = true;

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (Platform.isIOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isMacOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  Future<void> showStatusNotification({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'dinoshare_transfers',
      'Dino Transfers',
      channelDescription: 'Transfer status alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        title,
        body,
        const NotificationDetails(android: android, iOS: darwin, macOS: darwin),
      );
    } catch (_) {}
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    if (!notificationsEnabled) return;
    const android = AndroidNotificationDetails(
      'dinoshare_transfers',
      'Dino Transfers',
      channelDescription: 'Transfer status alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        title,
        body,
        const NotificationDetails(android: android, iOS: darwin, macOS: darwin),
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Socket utilities
  // ─────────────────────────────────────────────────────────────────────────

  void _setSocketOptions(Socket socket) {
    try {
      if (!Platform.isWindows) {
        socket.setOption(SocketOption.tcpNoDelay, true);
      }
      socket.setRawOption(
        RawSocketOption(_kSolSocket, _kSoSndbuf, _int32LE(_socketBuffer)),
      );
      socket.setRawOption(
        RawSocketOption(_kSolSocket, _kSoRcvbuf, _int32LE(_socketBuffer)),
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Misc
  // ─────────────────────────────────────────────────────────────────────────

  bool _isExpectedClosure(Object err) {
    final s = err.toString().toLowerCase();
    return s.contains('connection closed') ||
        s.contains('connection reset') ||
        s.contains('broken pipe') ||
        s.contains('software caused connection abort') ||
        s.contains('connection aborted');
  }

  String _buildSessionId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(999999999)}';
  }

  String _buildDeviceId() {
    return '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(999999999)}';
  }

  Future<String> _loadOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kDeviceId);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }

    final generated = _buildDeviceId();
    await prefs.setString(_kDeviceId, generated);
    return generated;
  }

  Future<String> localIpAddress() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        if (iface.addresses.isNotEmpty) {
          return iface.addresses.first.address;
        }
      }
    } catch (_) {}
    return '';
  }
}

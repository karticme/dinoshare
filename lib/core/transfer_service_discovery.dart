part of 'transfer_service.dart';

/// Adds discovery methods to DinoshareTransferService
extension DiscoveryX on DinoshareTransferService {
  // ─────────────────────────────────────────────────────────────────────────
  // Discovery
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> startDiscovery() async {
    await initialize();
    _discovering = true;
    await _refreshDiscoveryTargets();
    await _ensureDiscoverySocket();
    try {
      await _joinMulticast();
    } catch (_) {}
    try {
      _sendDiscoverPing();
    } catch (_) {}
    unawaited(_startBonjourDiscovery());
    _discoverTimer?.cancel();
    _discoverTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      runZonedGuarded(() => _sendDiscoverPing(), (_, _) {});
    });
    _peerPruneTimer?.cancel();
    _peerPruneTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      runZonedGuarded(() {
        final now = DateTime.now();
        _peerMap.removeWhere(
          (id, peer) =>
              !_bonjourPeerIds.contains(id) &&
              now.difference(peer.lastSeen) > const Duration(seconds: 6),
        );
        discoveredPeers.value =
            _peerMap.values.toList()..sort((a, b) => a.name.compareTo(b.name));
      }, (_, _) {});
    });
  }

  Future<void> stopDiscovery() async {
    _discovering = false;
    _discoverTimer?.cancel();
    _peerPruneTimer?.cancel();
    _discoverTimer = null;
    _peerPruneTimer = null;
    _peerMap.clear();
    _bonjourPeerIds.clear();
    discoveredPeers.value = [];
    if (_multicastJoined && !_receivingEnabled) await _leaveMulticast();
    unawaited(_stopBonjourDiscovery());
  }

  Future<void> _ensureDiscoverySocket() async {
    if (_discoverySocket != null) return;
    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _kDiscoveryPort,
        reuseAddress: true,
      );
      _discoverySocket!.broadcastEnabled = true;
      _discoverySocket!.listen(_handleDiscoveryEvent, onError: (_) {});
    } catch (_) {
      _discoverySocket = null;
    }
  }

  Future<void> _joinMulticast() async {
    if (_multicastJoined || _discoverySocket == null) return;
    try {
      _discoverySocket!.joinMulticast(InternetAddress(_kGroupAddress));
      _multicastJoined = true;
    } catch (_) {
      _multicastJoined = true;
    }
  }

  Future<void> _leaveMulticast() async {
    if (!_multicastJoined || _discoverySocket == null) return;
    try {
      _discoverySocket!.leaveMulticast(InternetAddress(_kGroupAddress));
    } catch (_) {}
    _multicastJoined = false;
  }

  void _sendDiscoverPing() {
    if (!_discovering || _discoverySocket == null) return;
    final payload = utf8.encode(_kDiscoverPing);
    for (final target in _discoveryTargets) {
      try {
        _discoverySocket!.send(payload, target, _kDiscoveryPort);
      } catch (_) {}
    }
  }

  Future<void> _refreshDiscoveryTargets() async {
    _discoveryTargets
      ..clear()
      ..add(InternetAddress(_kGroupAddress))
      ..add(InternetAddress('255.255.255.255'));
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          final bcast = _directedBroadcast(addr);
          if (bcast != null) _discoveryTargets.add(bcast);
        }
      }
    } catch (_) {}
  }

  InternetAddress? _directedBroadcast(InternetAddress addr) {
    final parts = addr.address.split('.');
    if (parts.length != 4) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return null;
    return InternetAddress('${nums[0]}.${nums[1]}.${nums[2]}.255');
  }

  void _handleDiscoveryEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final socket = _discoverySocket;
    if (socket == null) return;
    final packet = socket.receive();
    if (packet == null) return;
    final message = utf8.decode(packet.data, allowMalformed: true);

    if (message == _kDiscoverPing && _receivingEnabled) {
      final reply = jsonEncode({
        'type': 'discover_response',
        'id': _deviceId,
        'name': _deviceName,
        'port': _controlPort,
        'deviceType': _getDeviceTypeString(),
      });
      try {
        socket.send(utf8.encode(reply), packet.address, packet.port);
      } catch (_) {}
      return;
    }

    if (!_discovering) return;
    try {
      final decoded = jsonDecode(message) as Map<String, dynamic>;
      if (decoded['type'] != 'discover_response') return;
      final id = decoded['id'] as String;
      if (id == _deviceId) return;
      final peer = PeerDevice(
        id: id,
        name: decoded['name'] as String,
        address: packet.address,
        port: decoded['port'] as int,
        lastSeen: DateTime.now(),
        deviceType: decoded['deviceType'] as String?,
      );
      _peerMap[id] = peer;
      discoveredPeers.value =
          _peerMap.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {}
  }
}

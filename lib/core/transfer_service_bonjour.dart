part of 'transfer_service.dart';

const String _kBonjourType = '_dinoshare._tcp';

extension BonjourX on DinoshareTransferService {
  Future<void> _startBonjourBroadcast() async {
    await _stopBonjourBroadcast();
    try {
      final service = BonsoirService(
        name: _deviceName,
        type: _kBonjourType,
        port: _controlPort,
        attributes: {'id': _deviceId, 'dtype': _getDeviceTypeString()},
      );
      _bonjourBroadcast = BonsoirBroadcast(
        service: service,
        printLogs: kDebugMode,
      );
      await _bonjourBroadcast!.ready;
      await _bonjourBroadcast!.start();
    } catch (e) {
      debugPrint('[Bonjour] Broadcast start failed: $e');
      _bonjourBroadcast = null;
    }
  }

  Future<void> _stopBonjourBroadcast() async {
    try {
      await _bonjourBroadcast?.stop();
    } catch (_) {}
    _bonjourBroadcast = null;
  }

  Future<void> _startBonjourDiscovery() async {
    await _stopBonjourDiscovery();
    try {
      _bonjourDiscovery = BonsoirDiscovery(
        type: _kBonjourType,
        printLogs: kDebugMode,
      );
      await _bonjourDiscovery!.ready;
      _bonjourDiscoverySub = _bonjourDiscovery!.eventStream!.listen(
        _handleBonjourEvent,
        onError: (e) => debugPrint('[Bonjour] Discovery stream error: $e'),
      );
      await _bonjourDiscovery!.start();
    } catch (e) {
      debugPrint('[Bonjour] Discovery start failed: $e');
      _bonjourDiscoverySub?.cancel();
      _bonjourDiscoverySub = null;
      _bonjourDiscovery = null;
    }
  }

  Future<void> _stopBonjourDiscovery() async {
    _bonjourDiscoverySub?.cancel();
    _bonjourDiscoverySub = null;
    try {
      await _bonjourDiscovery?.stop();
    } catch (_) {}
    _bonjourDiscovery = null;
    for (final id in _bonjourPeerIds) {
      _peerMap.remove(id);
    }
    _bonjourPeerIds.clear();
  }

  void _handleBonjourEvent(BonsoirDiscoveryEvent event) {
    if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
      debugPrint('[Bonjour] Service found: ${event.service?.name}');
      try {
        event.service?.resolve(_bonjourDiscovery!.serviceResolver);
      } catch (e) {
        debugPrint('[Bonjour] Resolve trigger failed: $e');
      }
    } else if (event.type ==
        BonsoirDiscoveryEventType.discoveryServiceResolved) {
      final s = event.service;
      if (s == null || s is! ResolvedBonsoirService) return;
      final attrs = s.attributes;
      final id = attrs['id'] ?? s.name;
      if (id == _deviceId) return;
      debugPrint(
        '[Bonjour] Service resolved: ${s.name} host=${s.host} port=${s.port}',
      );
      _addBonjourPeer(
        id: id,
        name: s.name,
        rawHost: s.host ?? '',
        port: s.port,
        deviceType: attrs['dtype'],
      );
    } else if (event.type ==
        BonsoirDiscoveryEventType.discoveryServiceResolveFailed) {
      debugPrint(
        '[Bonjour] Resolve failed for ${event.service?.name} — retrying',
      );
      // Retry resolution after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (_bonjourDiscovery != null && event.service != null) {
          try {
            event.service!.resolve(_bonjourDiscovery!.serviceResolver);
          } catch (_) {}
        }
      });
    } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
      final s = event.service;
      if (s == null) return;
      final attrs =
          (s is ResolvedBonsoirService) ? s.attributes : <String, String>{};
      final id = attrs['id'] ?? s.name;
      debugPrint('[Bonjour] Service lost: ${s.name}');
      _bonjourPeerIds.remove(id);
      _peerMap.remove(id);
      discoveredPeers.value =
          _peerMap.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void _addBonjourPeer({
    required String id,
    required String name,
    required String rawHost,
    required int port,
    String? deviceType,
  }) {
    // DNSServiceResolve returns a hostname like "MyDevice.local." — strip trailing dots
    final host =
        rawHost.endsWith('.')
            ? rawHost.substring(0, rawHost.length - 1)
            : rawHost;

    final addr = InternetAddress.tryParse(host);
    if (addr != null) {
      _commitBonjourPeer(
        id: id,
        name: name,
        address: addr,
        port: port,
        deviceType: deviceType,
      );
      return;
    }

    if (host.isEmpty) return;

    // hostname (e.g. "MyDevice.local") — resolve to IP, prefer IPv4
    InternetAddress.lookup(host, type: InternetAddressType.IPv4)
        .then((list) {
          if (list.isNotEmpty) {
            _commitBonjourPeer(
              id: id,
              name: name,
              address: list.first,
              port: port,
              deviceType: deviceType,
            );
          } else {
            // fall back to any address type
            return InternetAddress.lookup(host).then((any) {
              if (any.isNotEmpty) {
                _commitBonjourPeer(
                  id: id,
                  name: name,
                  address: any.first,
                  port: port,
                  deviceType: deviceType,
                );
              } else {
                debugPrint('[Bonjour] Could not resolve host: $host');
              }
            });
          }
        })
        .catchError((Object e) {
          debugPrint('[Bonjour] DNS lookup failed for $host: $e');
        });
  }

  void _commitBonjourPeer({
    required String id,
    required String name,
    required InternetAddress address,
    required int port,
    String? deviceType,
  }) {
    debugPrint('[Bonjour] Peer ready: $name @ ${address.address}:$port');
    final peer = PeerDevice(
      id: id,
      name: name,
      address: address,
      port: port,
      lastSeen: DateTime(9999),
      deviceType: deviceType,
    );
    _bonjourPeerIds.add(id);
    _peerMap[id] = peer;
    discoveredPeers.value =
        _peerMap.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}

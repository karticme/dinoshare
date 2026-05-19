part of 'transfer_service.dart';

/// Adds receiver methods to DinoshareTransferService
extension ReceiverX on DinoshareTransferService {
  // ─────────────────────────────────────────────────────────────────────────
  // Receiver
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> startReceiver({required String deviceName}) async {
    debugPrint(
      '[TransferService] startReceiver called with deviceName=$deviceName',
    );
    await initialize();
    _deviceName = deviceName.trim().isEmpty ? 'Dino Device' : deviceName.trim();
    if (_receivingEnabled && _controlServer != null) {
      debugPrint('[TransferService] Receiver already running, returning');
      return;
    }
    if (_controlServer == null) {
      _controlPort = await _pickFreePort();
      debugPrint(
        '[TransferService] Binding control server on port $_controlPort',
      );
      _controlServer = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        _controlPort,
        shared: true,
      );
      _controlServer!.listen(_handleControlConnection);
      debugPrint('[TransferService] Control server listening on $_controlPort');
    }
    _receivingEnabled = true;
    await _refreshDiscoveryTargets();
    await _ensureDiscoverySocket();
    await _joinMulticast();
    _discoverySocket?.readEventsEnabled = true;
    debugPrint(
      '[TransferService] Receiver started, broadcasting as $_deviceName',
    );
    unawaited(_startBonjourBroadcast());
  }

  Future<void> stopReceiver() async {
    _receivingEnabled = false;
    await _stopBonjourBroadcast();
    await _controlServer?.close();
    _controlServer = null;
    for (final pending in _pendingIncoming.values) {
      pending.socket.destroy();
    }
    _pendingIncoming.clear();
    incomingRequest.value = null;
    if (_multicastJoined && !_discovering) await _leaveMulticast();
  }

  Future<bool> respondToIncoming({
    required String sessionId,
    required bool accept,
  }) async {
    _localStopRequested = false;
    final pending = _pendingIncoming.remove(sessionId);
    if (pending == null) return false;

    if (_sessionKey == null) {
      pending.socket.destroy();
      incomingRequest.value = null;
      return false;
    }

    if (!accept) {
      debugPrint(
        '[TransferService] Rejecting incoming request $sessionId by user action',
      );
      try {
        await _writeEncryptedJson(pending.socket, {
          'type': 'reject',
          'sessionId': sessionId,
          'reason': 'user_declined',
        }, _sessionKey!);
        await pending.socket.flush();
      } catch (_) {}
      await pending.socket.close();
      incomingRequest.value = null;
      return false;
    }

    if (_normalizeReceiveBasePath(_receiveBasePath) == null) {
      _receiveBasePath = await defaultReceiveDirectory();
    }
    final dir = Directory(_receiveBasePath);
    if (!dir.existsSync()) {
      try {
        await dir.create(recursive: true);
      } catch (_) {}
    }

    final topLevelSizes = <String, int>{};
    for (final f in pending.request.files) {
      topLevelSizes[f.topLevelName] =
          (topLevelSizes[f.topLevelName] ?? 0) + f.sizeBytes;
    }
    final allItems =
        topLevelSizes.entries
            .map(
              (e) => TransferItemProgress(
                name: e.key,
                sizeBytes: e.value,
                bytesTransferred: 0,
              ),
            )
            .toList();

    activeSession.value = TransferSession(
      sessionId: sessionId,
      role: TransferRole.receiving,
      status: TransferStatus.inProgress,
      peerName: pending.request.senderName,
      totalBytes: pending.request.totalBytes,
      bytesTransferred: 0,
      currentFile: null,
      currentSpeedBytesPerSec: 0,
      peakSpeedBytesPerSec: 0,
      topLevelCount: pending.request.topLevelCount,
      startedAt: DateTime.now(),
      completedItems: const [],
      allItems: allItems,
      files: pending.request.files,
    );
    _startSpeedTimer();
    _resetSpeedCounters();

    try {
      await _writeEncryptedJson(pending.socket, {
        'type': 'accept',
        'sessionId': sessionId,
      }, _sessionKey!);
      await pending.socket.flush();
    } catch (err) {
      debugPrint('DinoshareTransferService: failed to send accept: $err');
      pending.socket.destroy();
      incomingRequest.value = null;
      _finishSession(
        status: TransferStatus.failed,
        error: 'Lost connection to sender.',
      );
      return false;
    }
    await pending.socket.close();
    incomingRequest.value = null;
    return true;
  }

  Future<bool> respondToIncomingText({
    required String sessionId,
    required bool accept,
  }) async {
    final pending = _pendingIncoming.remove(sessionId);
    if (pending == null) return false;

    if (_sessionKey == null) {
      pending.socket.destroy();
      incomingRequest.value = null;
      return false;
    }

    try {
      await _writeEncryptedJson(pending.socket, {
        'type': accept ? 'accept' : 'reject',
        'sessionId': sessionId,
        if (!accept) 'reason': 'user_declined',
      }, _sessionKey!);
      await pending.socket.flush();
    } catch (_) {
      pending.socket.destroy();
      incomingRequest.value = null;
      return false;
    }

    await pending.socket.close();
    incomingRequest.value = null;
    return accept;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Control-server: handles all incoming TCP connections
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleControlConnection(Socket socket) async {
    _activeSockets.add(socket);
    _setSocketOptions(socket);
    final reader = _SocketStreamReader(socket);
    try {
      final firstLine = await reader.readLine();
      final payload = jsonDecode(firstLine) as Map<String, dynamic>;
      final type = payload['type'] as String?;

      if (type == 'hello') {
        await _handleHello(reader, socket, payload);
        return;
      }
      if (type == 'file_hello') {
        await _handleFileHello(reader, socket, payload);
        return;
      }
      if (type == 'transfer_stop') {
        await _handleTransferStop(payload);
        await socket.close();
        return;
      }
    } catch (err) {
      debugPrint('DinoshareTransferService: control error: $err');
      socket.destroy();
    } finally {
      _activeSockets.remove(socket);
    }
  }

  Future<void> _handleHello(
    _SocketStreamReader reader,
    Socket socket,
    Map<String, dynamic> payload,
  ) async {
    if (!_receivingEnabled) {
      socket.destroy();
      return;
    }

    final sessionId = payload['sessionId'] as String;
    final senderName = payload['senderName'] as String;
    final senderId = (payload['senderId'] as String?) ?? senderName;
    final senderDeviceType = payload['senderDeviceType'] as String?;
    final senderPubKeyBytes = base64Decode(payload['pubKey'] as String);
    final senderFullPower = (payload['fullPower'] as bool?) ?? false;

    final myCrypto = await _generateCrypto();
    await myCrypto.deriveKey(senderPubKeyBytes, sessionId);
    _sessionKey = myCrypto.sessionKey;

    final ackJson = jsonEncode({
      'type': 'hello_ack',
      'pubKey': base64Encode(myCrypto.publicKeyBytes),
      'fullPower': _fullPowerMode,
    });
    socket.add(utf8.encode('$ackJson\n'));
    await socket.flush();

    final request = await _readEncryptedJson(reader, _sessionKey!);
    if (request['type'] != 'transfer_request') {
      socket.destroy();
      return;
    }

    final files =
        (request['files'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TransferFileEntry.fromJson)
            .toList();
    final totalBytes = request['totalBytes'] as int;
    final topLevelCount = request['topLevelCount'] as int;
    final hasText = files.any((file) => file.isText);

    if (!hasText && _normalizeReceiveBasePath(_receiveBasePath) == null) {
      _receiveBasePath = await defaultReceiveDirectory();
    }
    if (!hasText) {
      final receiveDir = Directory(_receiveBasePath);
      if (!receiveDir.existsSync()) {
        try {
          await receiveDir.create(recursive: true);
        } catch (err) {
          debugPrint(
            '[TransferService] Could not create receive directory '
            '$_receiveBasePath before showing request: $err',
          );
        }
      }
      final hasSpace = await _hasSufficientSpace(_receiveBasePath, totalBytes);
      if (!hasSpace) {
        debugPrint(
          '[TransferService] Rejecting incoming request $sessionId because '
          'receive path $_receiveBasePath does not have enough free space '
          'for $totalBytes bytes',
        );
        try {
          await _writeEncryptedJson(socket, {
            'type': 'reject',
            'reason': 'disk_full',
          }, _sessionKey!);
          await socket.flush();
        } catch (_) {}
        await socket.close();
        return;
      }
    }

    _peerAddress = socket.remoteAddress;
    final senderControlPort = payload['controlPort'];
    if (senderControlPort is int && senderControlPort > 0) {
      _peerControlPort = senderControlPort;
    }

    final incoming = IncomingTransferRequest(
      sessionId: sessionId,
      senderId: senderId,
      senderName: senderName,
      files: files,
      totalBytes: totalBytes,
      topLevelCount: topLevelCount,
      senderDeviceType: senderDeviceType,
      senderFullPower: senderFullPower,
    );
    debugPrint(
      '[TransferService] Incoming request from $senderName, sessionId=$sessionId',
    );

    if (!hasText && isFavouriteDevice(senderId)) {
      debugPrint(
        '[TransferService] Sender $senderName is a favourite device, auto-accepting',
      );
      _pendingIncoming[sessionId] = _PendingIncoming(
        request: incoming,
        socket: socket,
      );
      await respondToIncoming(sessionId: sessionId, accept: true);
      return;
    }

    _pendingIncoming[sessionId] = _PendingIncoming(
      request: incoming,
      socket: socket,
    );
    debugPrint(
      '[TransferService] Setting incomingRequest.value to $senderName',
    );
    incomingRequest.value = incoming;
    debugPrint(
      '[TransferService] incomingRequest.value is now: ${incomingRequest.value?.senderName}',
    );
  }

  Future<void> _handleFileHello(
    _SocketStreamReader reader,
    Socket socket,
    Map<String, dynamic> payload,
  ) async {
    final sessionId = payload['sessionId'] as String;
    final session = activeSession.value;
    if (session == null ||
        session.status != TransferStatus.inProgress ||
        sessionId != session.sessionId) {
      socket.destroy();
      return;
    }
    if (_sessionKey == null) {
      socket.destroy();
      return;
    }

    late Map<String, dynamic> header;
    try {
      header = await _readEncryptedJson(reader, _sessionKey!);
    } catch (_) {
      socket.destroy();
      return;
    }

    final relativePath = _sanitizeRelativePath(
      header['relativePath'] as String,
    );
    final fileName = _sanitizeFileName(header['name'] as String);
    final totalFileSize = header['sizeBytes'] as int;
    final topLevelName = _sanitizeFileName(header['topLevelName'] as String);
    final isChunked =
        header.containsKey('totalChunks') &&
        (header['totalChunks'] as int? ?? 1) > 1;

    _setCurrentFile(fileName);
    if (_currentTopLevelName != topLevelName) {
      _currentTopLevelName = topLevelName;
      _topLevelStartBytes = session.bytesTransferred;
    }

    final outputPath = p.join(_receiveBasePath, relativePath);
    final outputFile = File(outputPath);
    try {
      if (!outputFile.parent.existsSync()) {
        await outputFile.parent.create(recursive: true);
      }
    } catch (err) {
      _finishSession(
        status: TransferStatus.failed,
        error: 'Could not create receive folder.',
      );
      socket.destroy();
      return;
    }

    try {
      if (isChunked) {
        final chunkOffset = header['chunkOffset'] as int;
        final chunkLength = header['chunkLength'] as int;
        final chunkIndex = header['chunkIndex'] as int;
        final totalChunks = header['totalChunks'] as int;
        await _receiveChunk(
          socket: socket,
          reader: reader,
          outputFile: outputFile,
          totalFileSize: totalFileSize,
          chunkOffset: chunkOffset,
          chunkLength: chunkLength,
          chunkIndex: chunkIndex,
          totalChunks: totalChunks,
          fileName: fileName,
          relativePath: relativePath,
          topLevelName: topLevelName,
          outputPath: outputPath,
        );
      } else {
        final sink = outputFile.openWrite();
        try {
          await _receiveEncryptedFileData(
            socket,
            reader,
            sink,
            totalFileSize,
            _sessionKey!,
            _onBytesMoved,
          );
          await sink.flush();
        } finally {
          await sink.close();
        }

        final mimeWarn = await mimeWarningForFile(outputFile, fileName);
        _appendCompleted(
          TransferCompletedItem(
            name: fileName,
            path: outputPath,
            sizeBytes: totalFileSize,
            relativePath: relativePath,
            topLevelName: topLevelName,
            mimeWarning: mimeWarn,
          ),
        );
      }
    } catch (err) {
      final latest = activeSession.value;
      if (latest == null ||
          latest.status == TransferStatus.stopped ||
          latest.status == TransferStatus.failed ||
          latest.status == TransferStatus.completed ||
          _localStopRequested) {
        socket.destroy();
        return;
      }
      if (_isExpectedClosure(err)) {
        _finishSession(
          status: TransferStatus.stopped,
          error: 'Stopped by Sender',
        );
        await _notifyStopped(activeSession.value);
      } else {
        _finishSession(
          status: TransferStatus.failed,
          error: 'Could not save file. Please try again.',
        );
        await _notifyFailed(activeSession.value);
      }
      socket.destroy();
      return;
    }

    await _writeEncryptedJson(socket, {
      'type': 'file_received',
      'ok': true,
    }, _sessionKey!);
    await socket.flush();
    await socket.close();

    final updated = activeSession.value;
    if (updated != null &&
        updated.completedItems.length >= updated.files.length) {
      _finishSession(status: TransferStatus.completed);
      await _notifyComplete(updated);
    }
  }

  Future<void> _receiveChunk({
    required Socket socket,
    required _SocketStreamReader reader,
    required File outputFile,
    required int totalFileSize,
    required int chunkOffset,
    required int chunkLength,
    required int chunkIndex,
    required int totalChunks,
    required String fileName,
    required String relativePath,
    required String topLevelName,
    required String outputPath,
  }) async {
    final key = relativePath;
    _chunkedFileProgress.putIfAbsent(key, () => {});

    final tempFile = File('${outputFile.path}.chunk$chunkIndex.tmp');
    final sink = tempFile.openWrite();
    try {
      await _receiveEncryptedFileData(
        socket,
        reader,
        sink,
        chunkLength,
        _sessionKey!,
        _onBytesMoved,
      );
      await sink.flush();
    } finally {
      await sink.close();
    }
    _chunkedFileProgress[key]!.add(chunkIndex);

    if (_chunkedFileProgress[key]!.length == totalChunks) {
      final raf = await outputFile.open(mode: FileMode.write);
      try {
        await raf.truncate(totalFileSize);
        for (var i = 0; i < totalChunks; i++) {
          final cf = File('${outputFile.path}.chunk$i.tmp');
          final bytes = await cf.readAsBytes();
          await raf.writeFrom(bytes);
          await cf.delete();
        }
        await raf.flush();
      } finally {
        await raf.close();
      }
      _chunkedFileProgress.remove(key);
      final mimeWarn = await mimeWarningForFile(outputFile, fileName);
      _appendCompleted(
        TransferCompletedItem(
          name: fileName,
          path: outputPath,
          sizeBytes: totalFileSize,
          relativePath: relativePath,
          topLevelName: topLevelName,
          mimeWarning: mimeWarn,
        ),
      );
    }
  }

  Future<void> _handleTransferStop(Map<String, dynamic> payload) async {
    final session = activeSession.value;
    final sessionId = payload['sessionId'] as String?;
    if (sessionId == null || session == null) return;
    if (session.status != TransferStatus.inProgress ||
        sessionId != session.sessionId) {
      return;
    }

    final by = payload['by'] as String? ?? 'peer';
    for (final s in _activeSockets) {
      s.destroy();
    }
    _activeSockets.clear();
    _finishSession(status: TransferStatus.stopped, error: 'Stopped by $by');
    await _notifyStopped(activeSession.value);
  }
}

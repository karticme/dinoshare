part of 'transfer_service.dart';

/// Adds sender methods to DinoshareTransferService
extension SenderX on DinoshareTransferService {
  // ─────────────────────────────────────────────────────────────────────────
  // Sending
  // ─────────────────────────────────────────────────────────────────────────

  Future<TransferStatus> sendTransferRequest({
    required PeerDevice peer,
    required TransferSelection selection,
    required String senderName,
  }) async {
    _localStopRequested = false;
    if (selection.files.isEmpty) return TransferStatus.failed;

    final sessionId = _buildSessionId();
    final started = DateTime.now();

    _sessionCrypto = await _generateCrypto();

    final topLevelSizes = <String, int>{};
    final topLevelPaths = <String, String>{};
    for (final f in selection.files) {
      topLevelSizes[f.topLevelName] =
          (topLevelSizes[f.topLevelName] ?? 0) + f.sizeBytes;
      if (!topLevelPaths.containsKey(f.topLevelName)) {
        if (f.topLevelName == f.name) {
          topLevelPaths[f.topLevelName] = f.sourcePath;
        } else {
          final depth = p.split(f.relativePath).length;
          var dir = f.sourcePath;
          for (var i = 0; i < depth; i++) {
            dir = p.dirname(dir);
          }
          topLevelPaths[f.topLevelName] = p.join(dir, f.topLevelName);
        }
      }
    }
    final allItems =
        topLevelSizes.entries
            .map(
              (e) => TransferItemProgress(
                name: e.key,
                sizeBytes: e.value,
                bytesTransferred: 0,
                path: topLevelPaths[e.key],
              ),
            )
            .toList();

    activeSession.value = TransferSession(
      sessionId: sessionId,
      role: TransferRole.sending,
      status: TransferStatus.requesting,
      peerName: peer.name,
      totalBytes: selection.totalBytes,
      bytesTransferred: 0,
      currentFile: null,
      currentSpeedBytesPerSec: 0,
      peakSpeedBytesPerSec: 0,
      topLevelCount: selection.topLevelCount,
      startedAt: started,
      completedItems: const [],
      allItems: allItems,
      files: selection.files,
    );
    _startSpeedTimer();

    _peerAddress = peer.address;
    _peerControlPort = peer.port;
    debugPrint('[TransferService] Sender connecting to peer ${peer.name} at ${peer.address}:${peer.port}');
    try {
      debugPrint('[TransferService] Attempting Socket.connect to ${peer.address}:${peer.port}');
      final handshakeSocket = await Socket.connect(
        peer.address,
        peer.port,
        timeout: const Duration(seconds: 5),
      );
      debugPrint('[TransferService] Socket connected successfully');
      _activeSockets.add(handshakeSocket);
      _setSocketOptions(handshakeSocket);

      final reader = _SocketStreamReader(handshakeSocket);

      if (_controlServer == null) {
        _controlPort = await _pickFreePort();
        _controlServer = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          _controlPort,
          shared: true,
        );
        _controlServer!.listen(_handleControlConnection);
      }

      final helloPayload = jsonEncode({
        'type': 'hello',
        'sessionId': sessionId,
        'senderId': peer.id,
        'senderName': senderName,
        'senderDeviceType': peer.deviceType,
        'pubKey': base64Encode(_sessionCrypto!.publicKeyBytes),
        'fullPower': _fullPowerMode,
        'controlPort': _controlPort,
      });
      debugPrint('[TransferService] Sending hello payload to receiver');
      handshakeSocket.add(utf8.encode('$helloPayload\n'));
      await handshakeSocket.flush();
      debugPrint('[TransferService] Waiting for hello_ack from receiver');

      final ackLine = await reader.readLine();
      debugPrint('[TransferService] Received ack line: $ackLine');
      final ack = jsonDecode(ackLine) as Map<String, dynamic>;
      if (ack['type'] != 'hello_ack') {
        debugPrint('[TransferService] ERROR: Expected hello_ack, got ${ack['type']}');
        _finishSession(
          status: TransferStatus.failed,
          error: 'Handshake failed',
        );
        await handshakeSocket.close();
        _activeSockets.remove(handshakeSocket);
        return TransferStatus.failed;
      }
      final receiverPubKeyBytes = base64Decode(ack['pubKey'] as String);
      final receiverFullPower = (ack['fullPower'] as bool?) ?? false;
      if (receiverFullPower && _fullPowerMode) {
      } else {
        _fullPowerMode = false;
      }

      await _sessionCrypto!.deriveKey(receiverPubKeyBytes, sessionId);
      _sessionKey = _sessionCrypto!.sessionKey;

      debugPrint('[TransferService] Sending transfer_request to receiver');
      await _writeEncryptedJson(handshakeSocket, {
        'type': 'transfer_request',
        'topLevelCount': selection.topLevelCount,
        'totalBytes': selection.totalBytes,
        'files': selection.files.map((f) => f.toJson()).toList(),
      }, _sessionKey!);
      await handshakeSocket.flush();

      debugPrint('[TransferService] Waiting for accept/reject response');
      final response = await _readEncryptedJson(reader, _sessionKey!);
      debugPrint('[TransferService] Received response: ${response['type']}');
      await handshakeSocket.close();
      _activeSockets.remove(handshakeSocket);

      if (response['type'] != 'accept') {
        _finishSession(status: TransferStatus.rejected);
        return TransferStatus.rejected;
      }
    } catch (err) {
      debugPrint('[TransferService] ERROR during handshake: $err');
      _finishSession(
        status: TransferStatus.failed,
        error: 'Could not connect to device.',
      );
      return TransferStatus.failed;
    }

    _setSessionStatus(TransferStatus.inProgress);
    _currentTransferFiles = selection.files;
    _topLevelStartBytes = 0;
    _resetSpeedCounters();

    try {
      await _sendFilesInParallel(
        peer: peer,
        sessionId: sessionId,
        files: selection.files,
      );
      _finishSession(status: TransferStatus.completed);
      await _notifyComplete(activeSession.value);
      return TransferStatus.completed;
    } catch (err) {
      if (_localStopRequested) return TransferStatus.stopped;
      if (_isExpectedClosure(err)) {
        _finishSession(
          status: TransferStatus.stopped,
          error: 'Stopped by Receiver',
        );
        await _notifyStopped(activeSession.value);
        return TransferStatus.stopped;
      }
      _finishSession(
        status: TransferStatus.failed,
        error: 'Transfer failed. Please try again.',
      );
      await _notifyFailed(activeSession.value);
      return TransferStatus.failed;
    }
  }

  Future<void> _sendFilesInParallel({
    required PeerDevice peer,
    required String sessionId,
    required List<TransferFileEntry> files,
  }) async {
    if (files.length == 1 && files.first.sizeBytes > _largeFileThreshold) {
      await _sendLargeFileInParallel(
        peer: peer,
        sessionId: sessionId,
        file: files.first,
      );
      return;
    }
    final errors = <String>[];
    var nextIdx = 0;
    var active = 0;
    var allStarted = false;
    final done = Completer<void>();

    void startNext() {
      while (active < _parallelConns && nextIdx < files.length) {
        final file = files[nextIdx];
        final isLast = nextIdx == files.length - 1;
        nextIdx++;
        active++;
        _sendSingleFile(
              peer: peer,
              sessionId: sessionId,
              file: file,
              isLast: isLast,
            )
            .then((_) {
              active--;
              if (!allStarted) startNext();
              if (active == 0 && allStarted && !done.isCompleted) {
                done.complete();
              }
            })
            .catchError((err) {
              errors.add('$err');
              active--;
              if (!allStarted) startNext();
              if (active == 0 && allStarted && !done.isCompleted) {
                done.complete();
              }
            });
      }
      if (nextIdx >= files.length) {
        allStarted = true;
        if (active == 0 && !done.isCompleted) done.complete();
      }
    }

    startNext();
    await done.future;
    if (errors.isNotEmpty) {
      throw StateError('Some files failed: ${errors.join('; ')}');
    }
  }

  Future<void> _sendLargeFileInParallel({
    required PeerDevice peer,
    required String sessionId,
    required TransferFileEntry file,
  }) async {
    final fileSize = file.sizeBytes;
    final numChunks = (fileSize / _parallelChunkSize).ceil().clamp(
      1,
      _parallelConns,
    );
    final chunkSize = (fileSize / numChunks).ceil();

    _setCurrentFile(file.name);

    final errors = <String>[];
    var active = 0;
    var completed = 0;
    final done = Completer<void>();

    for (var i = 0; i < numChunks; i++) {
      final offset = i * chunkSize;
      final length = min(chunkSize, fileSize - offset);
      final idx = i;
      if (i > 0) await Future.delayed(const Duration(milliseconds: 50));
      active++;

      _sendFileChunk(
            peer: peer,
            sessionId: sessionId,
            file: file,
            chunkOffset: offset,
            chunkLength: length,
            chunkIndex: idx,
            totalChunks: numChunks,
            isLastFile: true,
          )
          .then((_) {
            active--;
            completed++;
            if (completed == numChunks && !done.isCompleted) {
              _appendCompleted(
                TransferCompletedItem(
                  name: file.name,
                  path: file.storedPath ?? file.sourcePath,
                  sizeBytes: file.sizeBytes,
                  relativePath: file.relativePath,
                  topLevelName: file.topLevelName,
                ),
              );
              done.complete();
            }
          })
          .catchError((err) {
            errors.add('chunk $idx: $err');
            active--;
            if (active == 0 && !done.isCompleted) done.complete();
          });
    }
    await done.future;
    if (errors.isNotEmpty) {
      throw StateError('Chunked send failed: ${errors.join('; ')}');
    }
  }

  Future<void> _sendFileChunk({
    required PeerDevice peer,
    required String sessionId,
    required TransferFileEntry file,
    required int chunkOffset,
    required int chunkLength,
    required int chunkIndex,
    required int totalChunks,
    required bool isLastFile,
  }) async {
    final socket = await Socket.connect(peer.address, peer.port);
    _activeSockets.add(socket);
    try {
      _setSocketOptions(socket);

      socket.add(
        utf8.encode(
          '${jsonEncode({'type': 'file_hello', 'sessionId': sessionId})}\n',
        ),
      );

      await _writeEncryptedJson(socket, {
        'type': 'file_chunk',
        'relativePath': file.relativePath,
        'name': file.name,
        'sizeBytes': file.sizeBytes,
        'topLevelName': file.topLevelName,
        'isLast': isLastFile && chunkIndex == totalChunks - 1,
        'chunkOffset': chunkOffset,
        'chunkLength': chunkLength,
        'chunkIndex': chunkIndex,
        'totalChunks': totalChunks,
      }, _sessionKey!);
      await socket.flush();

      final reader = _SocketStreamReader(socket);
      final raf = await File(file.sourcePath).open();
      try {
        await raf.setPosition(chunkOffset);
        await _sendEncryptedFileData(
          socket,
          reader,
          raf,
          chunkLength,
          _sessionKey!,
          _onBytesMoved,
        );
      } finally {
        await raf.close();
      }
      await socket.flush();

      final ack = await _readEncryptedJson(reader, _sessionKey!);
      if (ack['type'] != 'file_received' || ack['ok'] != true) {
        throw StateError('Receiver rejected chunk $chunkIndex of ${file.name}');
      }
    } finally {
      await socket.close();
      _activeSockets.remove(socket);
    }
  }

  Future<void> _sendSingleFile({
    required PeerDevice peer,
    required String sessionId,
    required TransferFileEntry file,
    required bool isLast,
  }) async {
    final fileRef = File(file.sourcePath);
    if (!fileRef.existsSync()) return;

    _setCurrentFile(file.name);
    final socket = await Socket.connect(peer.address, peer.port);
    _activeSockets.add(socket);
    try {
      _setSocketOptions(socket);

      socket.add(
        utf8.encode(
          '${jsonEncode({'type': 'file_hello', 'sessionId': sessionId})}\n',
        ),
      );

      await _writeEncryptedJson(socket, {
        'type': 'file_chunk',
        'relativePath': file.relativePath,
        'name': file.name,
        'sizeBytes': file.sizeBytes,
        'topLevelName': file.topLevelName,
        'isLast': isLast,
      }, _sessionKey!);
      await socket.flush();

      final reader = _SocketStreamReader(socket);
      final raf = await fileRef.open();
      try {
        await _sendEncryptedFileData(
          socket,
          reader,
          raf,
          file.sizeBytes,
          _sessionKey!,
          _onBytesMoved,
        );
      } finally {
        await raf.close();
      }
      await socket.flush();

      final ack = await _readEncryptedJson(reader, _sessionKey!);
      if (ack['type'] != 'file_received' || ack['ok'] != true) {
        throw StateError('Receiver rejected ${file.name}');
      }

      _appendCompleted(
        TransferCompletedItem(
          name: file.name,
          path: file.storedPath ?? file.sourcePath,
          sizeBytes: file.sizeBytes,
          relativePath: file.relativePath,
          topLevelName: file.topLevelName,
        ),
      );
    } finally {
      await socket.close();
      _activeSockets.remove(socket);
    }
  }
}

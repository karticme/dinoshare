part of 'transfer_service.dart';

enum TransferRole { sending, receiving }

enum TransferStatus {
  idle,
  requesting,
  inProgress,
  completed,
  rejected,
  failed,
  stopped,
}

class PeerDevice {
  const PeerDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.lastSeen,
    this.deviceType,
  });

  final String id;
  final String name;
  final InternetAddress address;
  final int port;
  final DateTime lastSeen;
  final String? deviceType;

  PeerDevice copyWith({DateTime? lastSeen, String? deviceType}) => PeerDevice(
    id: id,
    name: name,
    address: address,
    port: port,
    lastSeen: lastSeen ?? this.lastSeen,
    deviceType: deviceType ?? this.deviceType,
  );
}

class TransferFileEntry {
  TransferFileEntry({
    required this.sourcePath,
    required this.relativePath,
    required this.name,
    required this.sizeBytes,
    required this.topLevelName,
    this.storedPath,
  });

  final String sourcePath;
  final String? storedPath;
  final String relativePath;
  final String name;
  final int sizeBytes;
  final String topLevelName;

  Future<String> get resolvedSourcePath => Future.value(sourcePath);

  Map<String, Object?> toJson() => {
    'relativePath': relativePath,
    'name': name,
    'sizeBytes': sizeBytes,
    'topLevelName': topLevelName,
  };

  static TransferFileEntry fromJson(Map<String, dynamic> j) =>
      TransferFileEntry(
        sourcePath: '',
        relativePath: j['relativePath'] as String,
        name: j['name'] as String,
        sizeBytes: j['sizeBytes'] as int,
        topLevelName: j['topLevelName'] as String,
      );
}

class TransferSelection {
  const TransferSelection({
    required this.files,
    required this.topLevelCount,
    required this.totalBytes,
    required this.labels,
  });

  final List<TransferFileEntry> files;
  final int topLevelCount;
  final int totalBytes;
  final List<String> labels;

  bool get isEmpty => files.isEmpty;
}

class TransferCompletedItem {
  const TransferCompletedItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.relativePath,
    this.topLevelName,
    this.mimeType,
    this.mimeWarning,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final String? relativePath;
  final String? topLevelName;
  final String? mimeType;
  final String? mimeWarning;
}

class TransferItemProgress {
  const TransferItemProgress({
    required this.name,
    required this.sizeBytes,
    required this.bytesTransferred,
    this.path,
  });

  final String name;
  final int sizeBytes;
  final int bytesTransferred;
  final String? path;

  bool get isCompleted => bytesTransferred >= sizeBytes;

  double get progress =>
      sizeBytes == 0 ? 1.0 : (bytesTransferred / sizeBytes).clamp(0.0, 1.0);

  TransferItemProgress copyWith({int? bytesTransferred, String? path}) =>
      TransferItemProgress(
        name: name,
        sizeBytes: sizeBytes,
        bytesTransferred: bytesTransferred ?? this.bytesTransferred,
        path: path ?? this.path,
      );
}

class IncomingTransferRequest {
  const IncomingTransferRequest({
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.files,
    required this.totalBytes,
    required this.topLevelCount,
    this.senderDeviceType,
    this.senderFullPower = false,
  });

  final String sessionId;
  final String senderId;
  final String senderName;
  final List<TransferFileEntry> files;
  final int totalBytes;
  final int topLevelCount;
  final String? senderDeviceType;
  final bool senderFullPower;
}

class TransferSession {
  const TransferSession({
    required this.sessionId,
    required this.role,
    required this.status,
    required this.peerName,
    required this.totalBytes,
    required this.bytesTransferred,
    required this.currentFile,
    required this.currentSpeedBytesPerSec,
    required this.peakSpeedBytesPerSec,
    required this.topLevelCount,
    required this.startedAt,
    required this.completedItems,
    required this.allItems,
    this.files = const [],
    this.endedAt,
    this.estimatedSecondsRemaining,
    this.error,
  });

  final String sessionId;
  final TransferRole role;
  final TransferStatus status;
  final String peerName;
  final int totalBytes;
  final int bytesTransferred;
  final String? currentFile;
  final double currentSpeedBytesPerSec;
  final double peakSpeedBytesPerSec;
  final int topLevelCount;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<TransferCompletedItem> completedItems;
  final List<TransferItemProgress> allItems;
  final List<TransferFileEntry> files;
  final int? estimatedSecondsRemaining;
  final String? error;

  Duration get totalTime {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  TransferSession copyWith({
    TransferStatus? status,
    int? bytesTransferred,
    String? currentFile,
    double? currentSpeedBytesPerSec,
    double? peakSpeedBytesPerSec,
    DateTime? endedAt,
    List<TransferCompletedItem>? completedItems,
    List<TransferItemProgress>? allItems,
    int? estimatedSecondsRemaining,
    String? error,
    bool clearCurrentFile = false,
    bool clearEta = false,
  }) => TransferSession(
    sessionId: sessionId,
    role: role,
    status: status ?? this.status,
    peerName: peerName,
    totalBytes: totalBytes,
    bytesTransferred: bytesTransferred ?? this.bytesTransferred,
    currentFile: clearCurrentFile ? null : (currentFile ?? this.currentFile),
    currentSpeedBytesPerSec:
        currentSpeedBytesPerSec ?? this.currentSpeedBytesPerSec,
    peakSpeedBytesPerSec: peakSpeedBytesPerSec ?? this.peakSpeedBytesPerSec,
    topLevelCount: topLevelCount,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    completedItems: completedItems ?? this.completedItems,
    allItems: allItems ?? this.allItems,
    files: files,
    estimatedSecondsRemaining:
        clearEta
            ? null
            : (estimatedSecondsRemaining ?? this.estimatedSecondsRemaining),
    error: error,
  );
}

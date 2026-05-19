part of 'state_index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data unit type
// ─────────────────────────────────────────────────────────────────────────────

enum DataUnitType {
  bytes('Byte'),
  bits('Bit');

  const DataUnitType(this.label);
  final String label;

  static DataUnitType fromLabel(String label) => DataUnitType.values.firstWhere(
    (e) => e.label == label,
    // Handle legacy stored values ('MB' → bytes, 'Mb' → bits).
    orElse: () => (label == 'Mb') ? bits : bytes,
  );

  /// Format [bytesPerSec] as a speed string, auto-scaled by magnitude.
  String formatSpeed(double bytesPerSec) {
    if (this == bits) {
      final bps = bytesPerSec * 8;
      if (bps >= 1e9) return '${(bps / 1e9).toStringAsFixed(2)} Gb/s';
      if (bps >= 1e6) return '${(bps / 1e6).toStringAsFixed(1)} Mb/s';
      return '${(bps / 1e3).toStringAsFixed(0)} Kb/s';
    }
    if (bytesPerSec >= 1e9) {
      return '${(bytesPerSec / 1e9).toStringAsFixed(2)} GB/s';
    }
    if (bytesPerSec >= 1e6) {
      return '${(bytesPerSec / 1e6).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSec / 1e3).toStringAsFixed(0)} KB/s';
  }

  /// Format [bytes] as a human-readable size, auto-scaled by magnitude.
  String formatSize(int bytes) {
    if (this == bits) {
      final b = bytes * 8;
      if (b >= 1e9) return '${(b / 1e9).toStringAsFixed(2)} Gb';
      if (b >= 1e6) return '${(b / 1e6).toStringAsFixed(1)} Mb';
      return '${(b / 1e3).toStringAsFixed(0)} Kb';
    }
    if (bytes >= 1000000000) return '${(bytes / 1e9).toStringAsFixed(2)} GB';
    if (bytes >= 1000000) return '${(bytes / 1e6).toStringAsFixed(1)} MB';
    return '${(bytes / 1e3).toStringAsFixed(0)} KB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History models
// ─────────────────────────────────────────────────────────────────────────────

class HistoryFileItem {
  const HistoryFileItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.relativePath,
    this.topLevelName,
    this.mimeWarning,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final String? relativePath;
  final String? topLevelName;
  final String? mimeWarning;

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'sizeBytes': sizeBytes,
    'relativePath': relativePath,
    'topLevelName': topLevelName,
    'mimeWarning': mimeWarning,
  };

  factory HistoryFileItem.fromJson(Map<String, dynamic> j) => HistoryFileItem(
    name: j['name'] as String,
    path: j['path'] as String,
    sizeBytes: j['sizeBytes'] as int,
    relativePath: j['relativePath'] as String?,
    topLevelName: j['topLevelName'] as String?,
    mimeWarning: j['mimeWarning'] as String?,
  );

  factory HistoryFileItem.fromCompleted(TransferCompletedItem item) =>
      HistoryFileItem(
        name: item.name,
        path: item.path,
        sizeBytes: item.sizeBytes,
        relativePath: item.relativePath,
        topLevelName: item.topLevelName,
        mimeWarning: item.mimeWarning,
      );
}

class TransferHistoryItem {
  const TransferHistoryItem({
    required this.id,
    required this.peerName,
    required this.isSending,
    required this.totalBytes,
    required this.fileCount,
    required this.completedAt,
    required this.durationSeconds,
    this.files = const [],
  });

  final String id;
  final String peerName;
  final bool isSending;
  final int totalBytes;
  final int fileCount;
  final DateTime completedAt;
  final int durationSeconds;
  final List<HistoryFileItem> files;

  List<String> get topLevelNames {
    final names = <String>{};
    for (final f in files) {
      names.add(f.topLevelName ?? f.name);
    }
    return names.isEmpty ? [peerName] : names.toList();
  }

  String get displayName {
    final names = topLevelNames;
    if (names.isEmpty) return 'Transfer';
    if (names.length == 1) return names.first;
    return '${names.first} +${names.length - 1} more';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'peerName': peerName,
    'isSending': isSending,
    'totalBytes': totalBytes,
    'fileCount': fileCount,
    'completedAt': completedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'files': files.map((f) => f.toJson()).toList(),
  };

  factory TransferHistoryItem.fromJson(Map<String, dynamic> j) =>
      TransferHistoryItem(
        id: j['id'] as String,
        peerName: j['peerName'] as String,
        isSending: j['isSending'] as bool,
        totalBytes: j['totalBytes'] as int,
        fileCount: j['fileCount'] as int,
        completedAt: DateTime.parse(j['completedAt'] as String),
        durationSeconds: (j['durationSeconds'] as int?) ?? 0,
        files:
            (j['files'] as List<dynamic>?)
                ?.map(
                  (f) => HistoryFileItem.fromJson(f as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );

  factory TransferHistoryItem.fromSession(TransferSession session) =>
      TransferHistoryItem(
        id: session.sessionId,
        peerName: session.peerName,
        isSending: session.role == TransferRole.sending,
        totalBytes: session.bytesTransferred,
        fileCount: session.completedItems.length,
        completedAt: session.endedAt ?? DateTime.now(),
        durationSeconds: session.totalTime.inSeconds,
        files:
            session.completedItems.map(HistoryFileItem.fromCompleted).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Share-item model
// ─────────────────────────────────────────────────────────────────────────────

class SelectedShareItem {
  const SelectedShareItem({
    required this.id,
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.files,
    this.isSent = false,
  });

  final String id;
  final String path;
  final String name;
  final bool isDirectory;
  final List<TransferFileEntry> files;
  final bool isSent;

  bool get isText => files.length == 1 && files.first.isText;

  int get totalBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);

  SelectedShareItem copyWith({bool? isSent}) => SelectedShareItem(
    id: id,
    path: path,
    name: name,
    isDirectory: isDirectory,
    files: files,
    isSent: isSent ?? this.isSent,
  );
}

class FavouriteDevice {
  const FavouriteDevice({
    required this.id,
    required this.name,
    this.deviceType,
  });

  final String id;
  final String name;
  final String? deviceType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deviceType': deviceType,
  };

  factory FavouriteDevice.fromJson(Map<String, dynamic> json) =>
      FavouriteDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        deviceType: json['deviceType'] as String?,
      );

  FavouriteDevice copyWith({String? name, String? deviceType}) =>
      FavouriteDevice(
        id: id,
        name: name ?? this.name,
        deviceType: deviceType ?? this.deviceType,
      );
}

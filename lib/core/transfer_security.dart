part of 'transfer_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// File-name sanitisation
// ─────────────────────────────────────────────────────────────────────────────

String _sanitizeFileName(String raw) {
  // Strip any path component — only take the basename.
  var name = p.basename(raw);
  // Remove null bytes and ASCII control characters.
  name = name.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  // Remove characters illegal on Windows/macOS/Linux paths.
  name = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  // Prevent path-traversal sequences that survive basename (e.g. on Windows).
  name = name.replaceAll('..', '_');
  if (name.trim().isEmpty) name = 'received_file';
  return name;
}

/// Sanitise a relative path that may contain subdirectories (folder transfers).
/// Each component is individually sanitised and rejoined.
String _sanitizeRelativePath(String raw) {
  final parts = raw.split(RegExp(r'[/\\]'));
  final sanitised =
      parts
          .map(_sanitizeFileName)
          .where((s) => s.isNotEmpty && s != '.')
          .toList();
  return sanitised.isEmpty ? 'received' : p.joinAll(sanitised);
}

// ─────────────────────────────────────────────────────────────────────────────
// MIME-type validation from file content (magic bytes)
// ─────────────────────────────────────────────────────────────────────────────

/// Extensions that are dangerous to auto-execute regardless of MIME type.
const Set<String> _kDangerousExtensions = {
  '.exe',
  '.msi',
  '.bat',
  '.cmd',
  '.com',
  '.scr',
  '.pif',
  '.vbs',
  '.vbe',
  '.js',
  '.jse',
  '.wsf',
  '.wsh',
  '.ps1',
  '.ps1xml',
  '.ps2',
  '.ps2xml',
  '.psc1',
  '.psc2',
  '.msh',
  '.msh1',
  '.msh2',
  '.inf',
  '.msp',
  '.gadget',
  '.sh',
  '.bash',
  '.zsh',
  '.fish',
  '.run',
  '.bin',
  '.apk',
  '.ipa',
  '.dmg',
  '.pkg',
  '.app',
  '.jar',
  '.class',
  '.deb',
  '.rpm',
  '.reg',
};

bool isDangerousFileName(String fileName) {
  final ext = p.extension(fileName).toLowerCase();
  return _kDangerousExtensions.contains(ext);
}

/// Reads the first 512 bytes of [file] and returns the detected MIME type,
/// or `null` if detection fails.
Future<String?> detectMimeFromContent(File file) async {
  try {
    final raf = await file.open();
    try {
      final header = await raf.read(512);
      return lookupMimeType(file.path, headerBytes: header);
    } finally {
      await raf.close();
    }
  } catch (_) {
    return null;
  }
}

/// Returns a warning string only if the file's magic bytes indicate a
/// genuinely dangerous type mismatch (e.g., an executable disguised as an
/// image). Benign mismatches (archive formats, ambiguous binary blobs) are
/// silently ignored to avoid false positives.
Future<String?> mimeWarningForFile(File file, String declaredName) async {
  final detectedMime = await detectMimeFromContent(file);
  if (detectedMime == null) return null;

  final extensionMime = lookupMimeType(declaredName);
  if (extensionMime == null) return null;

  // Identical — fine.
  if (detectedMime == extensionMime) return null;

  // Same top-level category (both image/*, both text/*, both audio/*, etc.) —
  // minor alias difference, not worth warning about.
  if (detectedMime.split('/').first == extensionMime.split('/').first) {
    return null;
  }

  // application/octet-stream and application/zip are generic containers used
  // by many legitimate formats (APK, DOCX, EPUB…). Not a security signal.
  const benignTypes = {
    'application/octet-stream',
    'application/zip',
    'application/x-zip-compressed',
  };
  if (benignTypes.contains(detectedMime) ||
      benignTypes.contains(extensionMime)) {
    return null;
  }

  // Only flag if magic bytes show an executable/script category masquerading
  // as a safe category (or vice-versa).
  const dangerousCategories = {'application'};
  final safeCategories = {'image', 'audio', 'video', 'text', 'font'};
  final detectedCat = detectedMime.split('/').first;
  final expectedCat = extensionMime.split('/').first;
  if (safeCategories.contains(expectedCat) &&
      dangerousCategories.contains(detectedCat)) {
    return 'Content type ($detectedMime) does not match extension ($extensionMime).';
  }

  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Disk-space check
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the number of free bytes available in [dirPath], or -1 on failure.
Future<int> _freeBytesAt(String dirPath) async {
  try {
    if (Platform.isWindows) {
      // `fsutil volume diskfree <drive>` returns three lines; the third has
      // "Total free bytes" in hex and decimal.
      final drive =
          p.rootPrefix(dirPath).isEmpty ? 'C:\\' : p.rootPrefix(dirPath);
      final result = await Process.run('cmd', [
        '/c',
        'fsutil volume diskfree $drive',
      ], runInShell: true);
      final lines = (result.stdout as String).split('\n');
      for (final line in lines) {
        if (line.contains('Total free bytes')) {
          final match = RegExp(r'(\d+)').firstMatch(line.split(':').last);
          if (match != null) return int.parse(match.group(1)!);
        }
      }
    } else {
      // `df -k <path>` on macOS/Linux/Android
      final result = await Process.run('df', ['-k', dirPath]);
      if (result.exitCode != 0) {
        debugPrint(
          '[TransferService] Could not check free space at $dirPath: '
          '${result.stderr}',
        );
        return -1;
      }
      final lines = (result.stdout as String).trim().split('\n');
      if (lines.length >= 2) {
        final parts = lines.last.trim().split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final kbFree = int.tryParse(parts[3]);
          if (kbFree != null) return kbFree * 1024;
        }
      }
    }
  } catch (_) {}
  return -1; // Unknown — caller decides whether to proceed.
}

/// Returns true if [dirPath] has at least [requiredBytes] of free space.
/// Returns true on failure (give benefit of doubt — don't block silently).
Future<bool> _hasSufficientSpace(String dirPath, int requiredBytes) async {
  final free = await _freeBytesAt(dirPath);
  if (free < 0) return true; // Could not determine
  // Leave 50 MB headroom on top of the transfer size.
  return free >= requiredBytes + 50 * 1024 * 1024;
}

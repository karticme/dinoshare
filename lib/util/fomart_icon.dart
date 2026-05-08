import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

class FileTypeIconData {
  final String fileType;
  final HugeIcon icon;

  const FileTypeIconData({required this.fileType, required this.icon});
}

FileTypeIconData fileTypeIconData(
  String fileName, {
  Color? color,
  double? size,
}) {
  final name = fileName.trim();
  final extension = _extensionFromFileName(name);

  const imageExt = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
    'heic',
    'tiff',
  };
  const videoExt = {'mp4', 'mov', 'mkv', 'avi', 'flv', 'webm', 'wmv'};
  const audioExt = {'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'};
  const archiveExt = {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'};
  const pdfExt = {'pdf'};
  const docExt = {'doc', 'docx', 'rtf', 'odt', 'pages'};
  const sheetExt = {'xls', 'xlsx', 'csv', 'numbers', 'ods'};
  const presentationExt = {'ppt', 'pptx', 'key', 'odp'};
  const codeExt = {
    'dart',
    'js',
    'ts',
    'jsx',
    'tsx',
    'py',
    'java',
    'kt',
    'kts',
    'swift',
    'c',
    'cpp',
    'h',
    'cs',
    'rb',
    'go',
    'rs',
    'php',
    'html',
    'css',
    'json',
    'xml',
    'yaml',
    'yml',
    'sh',
    'bash',
  };
  const textExt = {'txt', 'md'};
  const figma = {'fig'};

  late final String type;
  late final HugeIcon icon;

  if (extension.isEmpty) {
    type = 'Unknown';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedFile01,
      color: color,
      size: size,
    );
  } else if (imageExt.contains(extension)) {
    type = 'Image';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedImage02,
      color: color,
      size: size,
    );
  } else if (videoExt.contains(extension)) {
    type = 'Video';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedVideo02,
      color: color,
      size: size,
    );
  } else if (audioExt.contains(extension)) {
    type = 'Audio';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedMusic3,
      color: color,
      size: size,
    );
  } else if (archiveExt.contains(extension)) {
    type = 'Archive';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedFileArchive,
      color: color,
      size: size,
    );
  } else if (pdfExt.contains(extension)) {
    type = 'PDF';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedFile02,
      color: color,
      size: size,
    );
  } else if (docExt.contains(extension)) {
    type = 'Document';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedDoc01,
      color: color,
      size: size,
    );
  } else if (sheetExt.contains(extension)) {
    type = 'Spreadsheet';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedFileSpreadsheet,
      color: color,
      size: size,
    );
  } else if (presentationExt.contains(extension)) {
    type = 'Presentation';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedPpt01,
      color: color,
      size: size,
    );
  } else if (codeExt.contains(extension)) {
    type = 'Code';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedVisualStudioCode,
      color: color,
      size: size,
    );
  } else if (textExt.contains(extension)) {
    type = 'Text';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedFiles01,
      color: color,
      size: size,
    );
  } else if (figma.contains(extension)) {
    type = 'Figma';
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedFigma,
      color: color,
      size: size,
    );
  } else {
    type = extension.toUpperCase();
    icon = HugeIcon(
      icon: HugeIcons.strokeRoundedFile01,
      color: color,
      size: size,
    );
  }

  return FileTypeIconData(fileType: type, icon: icon);
}

String _extensionFromFileName(String fileName) {
  final file = fileName.trim().split(RegExp(r'[\\/]+')).last;
  final segments = file.split('.');
  if (segments.length < 2) {
    return '';
  }
  return segments.last.toLowerCase();
}

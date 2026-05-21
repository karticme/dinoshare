import 'dart:io';
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'package:dinoshare/state/drop_route_observer.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

class DesktopDropOverlay extends StatefulWidget {
  const DesktopDropOverlay({
    super.key,
    required this.child,
    required this.onDropNavigate,
  });

  final Widget child;
  final VoidCallback onDropNavigate;

  @override
  State<DesktopDropOverlay> createState() => _DesktopDropOverlayState();
}

class _DesktopDropOverlayState extends State<DesktopDropOverlay> {
  bool _dragging = false;

  static const _excludedRoutes = {'receive', 'transfer', 'transfer_done'};

  bool get _isExcluded {
    final name = dropRouteObserver.currentRouteName;
    return name != null && _excludedRoutes.contains(name);
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktop()) return widget.child;
    if (_isExcluded) return widget.child;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) => _onDrop(details),
      child: Stack(
        children: [
          widget.child,
          if (_dragging) _buildOverlay(context),
        ],
      ),
    );
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);

    final paths = await _resolvePaths(details);
    if (paths.isEmpty) return;

    await addDropTargets(paths);

    if (!mounted) return;
    if (dropRouteObserver.currentRouteName != 'share') {
      widget.onDropNavigate();
    }
  }

  Future<List<String>> _resolvePaths(DropDoneDetails details) async {
    final paths = <String>[];
    for (final file in details.files) {
      if (file.path.isEmpty) continue;

      if (Platform.isMacOS && file.extraAppleBookmark != null) {
        final resolved = await _resolveBookmarkedPath(file);
        if (resolved != null) paths.add(resolved);
      } else {
        paths.add(file.path);
      }
    }
    return paths;
  }

  Future<String?> _resolveBookmarkedPath(DropItem file) async {
    final bookmark = file.extraAppleBookmark;
    if (bookmark == null) return null;

    await DesktopDrop.instance.startAccessingSecurityScopedResource(
      bookmark: bookmark,
    );
    try {
      final originalName = p.basename(file.path);
      var tempPath = '${Directory.systemTemp.path}/$originalName';
      int dedup = 0;
      while (FileSystemEntity.typeSync(tempPath) !=
          FileSystemEntityType.notFound) {
        dedup++;
        final stem = p.basenameWithoutExtension(originalName);
        final ext = p.extension(originalName);
        tempPath = '${Directory.systemTemp.path}/${stem}_$dedup$ext';
      }

      final entityType = FileSystemEntity.typeSync(file.path);
      if (entityType == FileSystemEntityType.directory) {
        final src = Directory(file.path);
        final tempDir = Directory(tempPath);
        await tempDir.create();
        await _copyDirectory(src, tempDir);
        return tempDir.path;
      } else {
        final srcFile = File(file.path);
        if (!await srcFile.exists()) return null;
        await srcFile.copy(tempPath);
        return tempPath;
      }
    } finally {
      await DesktopDrop.instance.stopAccessingSecurityScopedResource(
        bookmark: bookmark,
      );
    }
  }

  Future<void> _copyDirectory(Directory src, Directory dst) async {
    await for (final entity in src.list(followLinks: false)) {
      final name = entity.uri.pathSegments.last;
      if (entity is File) {
        await entity.copy('${dst.path}/$name');
      } else if (entity is Directory) {
        final sub = Directory('${dst.path}/$name');
        await sub.create();
        await _copyDirectory(entity, sub);
      }
    }
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned.fill(
      child: MouseRegion(
        cursor: SystemMouseCursors.copy,
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 56, 20, 20),
          color: theme.colors.barrier,
          child: Row(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: lCustom.info,
                    strokeWidth: 2.5,
                    borderRadius: 10,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 16,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: lCustom.info.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedUpload01,
                              size: 32,
                              color: lCustom.info,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        DText(
                          'Drop here',
                          size: DTextSize.h2,
                          color: theme.colors.foreground,
                        ),
                        DText(
                          'Add files/folders/etc\nto share with a local device',
                          size: DTextSize.sm,
                          weight: FontWeight.w500,
                          color: theme.colors.foreground.withAlpha(160),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  bool isDesktop() =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);

    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6.0).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += 14.0;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius;
}

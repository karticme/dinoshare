import 'dart:io';

import 'package:dinoshare/pages/folder_details.dart';
import 'package:dinoshare/pages/home.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/incoming_transfer_overlay.dart';

class TransferDone extends StatelessWidget {
  const TransferDone({super.key, required this.session});

  final TransferSession session;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DataUnitType>(
      valueListenable: appDataUnit,
      builder: (context, unit, _) => _build(context, unit),
    );
  }

  Widget _build(BuildContext context, DataUnitType unit) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    final completedBytes = session.completedItems.fold<int>(
      0,
      (sum, item) => sum + item.sizeBytes,
    );
    final receivedSize = unit.formatSize(completedBytes);
    final fileCount = session.completedItems.length;
    final fileCountLabel = '$fileCount file${fileCount == 1 ? '' : 's'}';
    final duration = session.totalTime;
    final durationLabel = _formatDuration(duration);
    final isStopped = session.status == TransferStatus.stopped;
    final displayItems = _topLevelItems(session.completedItems);
    final isTextOnly = session.files.every((f) => f.isText);

    return IncomingTransferOverlay(
      child: Container(
        color: theme.colors.secondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DHeader(
              nested: true,
              suffix: [
                DButton(
                  size: DButtonSize.xs,
                  variant: DButtonVariant.ghost,
                  textColor: lCustom.info,
                  style:
                      Platform.isAndroid || Platform.isIOS
                          ? const DButtonStyle(width: 64)
                          : null,
                  child: Text('Done'),
                  onPressed: () => _goHome(context),
                ),
              ],
              title: isStopped ? 'Stopped' : 'Completed',
            ),
            if (!isTextOnly)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 2,
                      children: [
                        DItem(
                          compact: true,
                          title: Text(fileCountLabel),
                          prefix: HugeIcon(
                            icon: HugeIcons.strokeRoundedFiles01,
                            size: 20,
                            color: theme.colors.primary,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: DItem(
                            title: Text(durationLabel),
                            prefix: HugeIcon(
                              icon: HugeIcons.strokeRoundedTimer01,
                              size: 20,
                              color: theme.colors.primary,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    DItem(
                      title: Text(receivedSize),
                      prefix: HugeIcon(
                        icon: HugeIcons.strokeRoundedDatabase01,
                        size: 20,
                        color: theme.colors.primary,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(14),
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                  ],
                ),
              ),
            if (isStopped)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildStopBanner(theme),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, 8),
              child: DText('Files', weight: FontWeight.w500),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: DItemList(
                    borderRadius: BorderRadius.circular(14),
                    children:
                        displayItems
                            .map(
                              (item) =>
                                  _buildFileItem(context, theme, unit, item),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    transferService.clearCompletedSession();
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
  }

  Widget _buildStopBanner(FThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colors.destructive.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.destructive.withAlpha(60)),
      ),
      child: Row(
        spacing: 12,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            size: 20,
            color: theme.colors.destructive,
          ),
          Expanded(
            child: Text(
              session.error ?? 'Transfer stopped',
              style: TextStyle(
                fontSize: 14,
                color: theme.colors.destructive,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    FThemeData theme,
    DataUnitType unit,
    _CompletedDisplayItem item,
  ) {
    final isTextItem = session.files.any(
      (f) => f.isText && (f.topLevelName == item.name || f.name == item.name),
    );
    final fileExists =
        !item.isFolder && item.path.isNotEmpty && storedFileExists(item.path);
    final bool anyFileExists;
    if (item.isFolder) {
      anyFileExists =
          item.children
              .any((c) => c.path.isNotEmpty && storedFileExists(c.path));
    } else {
      anyFileExists = fileExists;
    }
    final isDisabled = !isTextItem && !anyFileExists;
    final canOpen = fileExists && !isDangerousFileName(item.name);
    final directionLabel =
        session.role == TransferRole.sending
            ? 'To ${session.peerName}'
            : 'From ${session.peerName}';

    return DItem(
      disabled: isDisabled,
      padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
      prefix:
          isTextItem
              ? Padding(
                padding: EdgeInsets.all(12),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedText,
                  size: 24,
                  color: theme.colors.primary,
                ),
              )
              : FileThumbnail(
                path: item.path,
                name: item.name,
                isDirectory: item.isFolder,
                size: 48,
                borderRadius: 8,
                iconColor: theme.colors.primary,
              ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      description: isTextItem ? null : Text(unit.formatSize(item.sizeBytes)),
      suffix:
          item.isFolder
              ? HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 16,
                color: theme.colors.mutedForeground,
              )
              : item.mimeWarning != null
              ? HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                size: 18,
                color: theme.colors.destructive,
              )
              : isTextItem
              ? _TextCopyButton(
                textContent:
                    session.files
                        .firstWhere(
                          (f) =>
                              f.isText &&
                              (f.topLevelName == item.name ||
                                  f.name == item.name),
                        )
                        .textContent ??
                    '',
                theme: theme,
              )
              : null,
      onPressed:
          item.isFolder
              ? () => _openFolder(context, item, directionLabel)
              : canOpen
              ? () => openStoredFile(item.path)
              : null,
    );
  }

  List<_CompletedDisplayItem> _topLevelItems(
    List<TransferCompletedItem> files,
  ) {
    final groups = <String, List<TransferCompletedItem>>{};
    for (final file in files) {
      groups.putIfAbsent(file.topLevelName ?? file.name, () => []).add(file);
    }

    return groups.entries.map((entry) {
      final group = entry.value;
      final first = group.first;
      final isFolder =
          group.length > 1 ||
          (first.topLevelName != null && first.topLevelName != first.name);
      if (!isFolder) {
        return _CompletedDisplayItem.file(first);
      }
      return _CompletedDisplayItem.folder(
        name: entry.key,
        path: _folderPath(first),
        sizeBytes: group.fold(0, (sum, file) => sum + file.sizeBytes),
        children: group,
      );
    }).toList();
  }

  String _folderPath(TransferCompletedItem item) {
    final relativePath = item.relativePath;
    final topLevelName = item.topLevelName;
    if (relativePath == null ||
        topLevelName == null ||
        topLevelName == item.name) {
      return item.path;
    }
    var path = item.path;
    final levelsToTop = relativePath.split(RegExp(r'[/\\]')).length - 1;
    for (var i = 0; i < levelsToTop; i++) {
      final separatorIndex = path.lastIndexOf(RegExp(r'[/\\]'));
      if (separatorIndex <= 0) return item.path;
      path = path.substring(0, separatorIndex);
    }
    return path;
  }

  void _openFolder(
    BuildContext context,
    _CompletedDisplayItem folder,
    String directionLabel,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder:
            (_) => FolderDetails(
              title: folder.name,
              directionLabel: directionLabel,
              isSending: session.role == TransferRole.sending,
              items:
                  folder.children
                      .map(
                        (file) => FolderContentItem(
                          name: file.name,
                          path: file.path,
                          sizeBytes: file.sizeBytes,
                          relativePath: file.relativePath,
                          mimeWarning: file.mimeWarning,
                        ),
                      )
                      .toList(),
            ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

class _TextCopyButton extends StatefulWidget {
  const _TextCopyButton({required this.textContent, required this.theme});

  final String textContent;
  final FThemeData theme;

  @override
  State<_TextCopyButton> createState() => _TextCopyButtonState();
}

class _TextCopyButtonState extends State<_TextCopyButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.textContent));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lCustom = dinoCustomColors(
      dark: widget.theme.colors.brightness == Brightness.dark,
    );
    return DButton(
      size: DButtonSize.sm,
      variant: DButtonVariant.ghost,
      onPressed: _copied ? null : _copy,
      child: HugeIcon(
        icon:
            _copied
                ? HugeIcons.strokeRoundedTick02
                : HugeIcons.strokeRoundedCopy01,
        color: _copied ? lCustom.success : widget.theme.colors.primary,
      ),
    );
  }
}

class _CompletedDisplayItem {
  const _CompletedDisplayItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.isFolder,
    required this.children,
    this.mimeWarning,
  });

  factory _CompletedDisplayItem.file(TransferCompletedItem file) =>
      _CompletedDisplayItem(
        name: file.name,
        path: file.path,
        sizeBytes: file.sizeBytes,
        isFolder: false,
        children: [file],
        mimeWarning: file.mimeWarning,
      );

  factory _CompletedDisplayItem.folder({
    required String name,
    required String path,
    required int sizeBytes,
    required List<TransferCompletedItem> children,
  }) => _CompletedDisplayItem(
    name: name,
    path: path,
    sizeBytes: sizeBytes,
    isFolder: true,
    children: children,
  );

  final String name;
  final String path;
  final int sizeBytes;
  final bool isFolder;
  final List<TransferCompletedItem> children;
  final String? mimeWarning;
}

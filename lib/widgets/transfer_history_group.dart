import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/pages/folder_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/util/fomart_icon.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/widgets/items.dart';

class TransferHistoryGroupView extends StatelessWidget {
  const TransferHistoryGroupView({super.key, required this.item});

  final TransferHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final files =
        item.files.isEmpty
            ? [
              HistoryFileItem(
                name: item.displayName,
                path: '',
                sizeBytes: item.totalBytes,
              ),
            ]
            : item.files;
    final displayItems = _topLevelItems(files);

    return DItemList(
      spacing: 2,
      borderRadius: BorderRadius.circular(14),
      children: [
        _buildDirectionItem(theme),
        for (final file in displayItems) _buildFileItem(context, theme, file),
      ],
    );
  }

  Widget _buildDirectionItem(FThemeData theme) {
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );
    final directionLabel =
        item.isSending ? 'To ${item.peerName}' : 'From ${item.peerName}';

    return DItem(
      spacing: 6,
      minHeight: 32,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      prefix: HugeIcon(
        icon:
            item.isSending
                ? HugeIcons.strokeRoundedArrowUpRight03
                : HugeIcons.strokeRoundedArrowDownLeft01,
        color: item.isSending ? lCustom.success : theme.colors.destructive,
        size: 16,
        strokeWidth: 2,
      ),
      title: DText(
        directionLabel,
        size: DTextSize.sm,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        weight: FontWeight.w400,
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    FThemeData theme,
    _HistoryDisplayItem file,
  ) {
    final isTextItem = file.path.isEmpty && !file.isFolder;
    final textContent = isTextItem ? file.children.first.textContent : null;
    final fileExists = file.path.isNotEmpty && storedFileExists(file.path);
    final directionLabel =
        item.isSending ? 'To ${item.peerName}' : 'From ${item.peerName}';

    return DItem(
      padding: isTextItem ? null : EdgeInsets.fromLTRB(8, 8, 16, 8),
      spacing: 12,
      prefix: isTextItem ? Padding(
        padding: EdgeInsets.fromLTRB(7, 0, 15, 0),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedText,
          size: 20,
          color: theme.colors.primary,
        ),
      ) : _buildFilePreview(theme, file),
      title: DText(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        weight: FontWeight.w500,
      ),
      description:
          file.path.isEmpty && !file.isFolder
              ? null
              : DText(
                  file.isFolder
                      ? directionLabel
                      : appDataUnit.value.formatSize(file.sizeBytes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: theme.colors.mutedForeground,
                  weight: FontWeight.w400,
                ),
      suffix:
          file.isFolder
              ? HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 16,
                color: theme.colors.mutedForeground,
              )
              : null,
      onPressed:
          file.isFolder
              ? () => _openFolder(context, file, directionLabel)
              : isTextItem && textContent != null
              ? () => Clipboard.setData(ClipboardData(text: textContent))
              : fileExists
              ? () => openStoredFile(file.path)
              : null,
    );
  }

  Widget _buildFilePreview(FThemeData theme, _HistoryDisplayItem file) {
    if (file.path.isEmpty && !file.isFolder) {
      return Padding(
        padding: EdgeInsets.all(12),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedText,
          size: 24,
          color: theme.colors.primary,
        ),
      );
    }
    if (!file.isFolder && file.path.isNotEmpty && storedFileExists(file.path)) {
      return FileThumbnail(
        path: file.path,
        name: file.name,
        size: 48,
        borderRadius: 6,
        iconColor: theme.colors.primary,
      );
    }

    final icon = fileTypeIconData(file.name);
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: HugeIcon(
          icon:
              file.isFolder ? HugeIcons.strokeRoundedFolder01 : icon.icon.icon,
          color: theme.colors.primary,
          size: 28,
        ),
      ),
    );
  }

  List<_HistoryDisplayItem> _topLevelItems(List<HistoryFileItem> files) {
    final groups = <String, List<HistoryFileItem>>{};
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
        return _HistoryDisplayItem.file(first);
      }
      return _HistoryDisplayItem.folder(
        name: entry.key,
        sizeBytes: group.fold(0, (sum, file) => sum + file.sizeBytes),
        children: group,
      );
    }).toList();
  }

  void _openFolder(
    BuildContext context,
    _HistoryDisplayItem folder,
    String directionLabel,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder:
            (_) => FolderDetails(
              title: folder.name,
              directionLabel: directionLabel,
              isSending: item.isSending,
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
}

class _HistoryDisplayItem {
  const _HistoryDisplayItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.isFolder,
    required this.children,
  });

  factory _HistoryDisplayItem.file(HistoryFileItem file) => _HistoryDisplayItem(
    name: file.name,
    path: file.path,
    sizeBytes: file.sizeBytes,
    isFolder: false,
    children: [file],
  );

  factory _HistoryDisplayItem.folder({
    required String name,
    required int sizeBytes,
    required List<HistoryFileItem> children,
  }) => _HistoryDisplayItem(
    name: name,
    path: '',
    sizeBytes: sizeBytes,
    isFolder: true,
    children: children,
  );

  final String name;
  final String path;
  final int sizeBytes;
  final bool isFolder;
  final List<HistoryFileItem> children;
}

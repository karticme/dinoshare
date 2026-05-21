import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as p;

class FolderContentItem {
  const FolderContentItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.relativePath,
    this.mimeWarning,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final String? relativePath;
  final String? mimeWarning;
}

class FolderDetails extends StatefulWidget {
  const FolderDetails({
    super.key,
    required this.title,
    required this.items,
    this.breadcrumb = const [],
    this.directionLabel,
    this.isSending = false,
  });

  final String title;
  final List<FolderContentItem> items;
  final List<String> breadcrumb;
  final String? directionLabel;
  final bool isSending;

  @override
  State<FolderDetails> createState() => _FolderDetailsState();
}

class _FolderDetailsState extends State<FolderDetails> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final displayItems = _currentItems();

    return Container(
      color: theme.colors.secondary,
      child: Column(
        children: [
          DHeader(
            nested: true,
            prefix: [
              DButton(
                size: DButtonSize.md,
                variant: DButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
              ),
            ],
            title: widget.title,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.directionLabel != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          spacing: 8,
                          children: [
                            HugeIcon(
                              icon:
                                  widget.isSending
                                      ? HugeIcons.strokeRoundedArrowUpRight03
                                      : HugeIcons.strokeRoundedArrowDownLeft01,
                              color:
                                  widget.isSending
                                      ? const Color(0xFF00A36C)
                                      : theme.colors.destructive,
                              size: 18,
                              strokeWidth: 2,
                            ),
                            DText(
                              widget.directionLabel!,
                              size: DTextSize.sm,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              weight: FontWeight.w400,
                            ),
                          ],
                        ),
                      ),
                    DItemList(
                      borderRadius: BorderRadius.circular(14),
                      children:
                          displayItems
                              .map((item) => _buildItem(context, item))
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(
                top: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            child: Row(children: [_buildBreadcrumb(theme)]),
          ),
        ],
      ),
    );
  }

  void _popToBreadcrumb(int index) {
    final crumbs =
        widget.breadcrumb.isEmpty ? [widget.title] : widget.breadcrumb;
    var count = crumbs.length - 1 - index;
    if (count <= 0) return;
    Navigator.of(context).popUntil((route) {
      if (count == 0) return true;
      count--;
      return false;
    });
  }

  Widget _buildBreadcrumb(FThemeData theme) {
    final crumbs =
        widget.breadcrumb.isEmpty ? [widget.title] : widget.breadcrumb;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: FBreadcrumb(
          children: [
            for (var i = 0; i < crumbs.length; i++)
              FBreadcrumbItem(
                current: i == crumbs.length - 1,
                onPress:
                    i == crumbs.length - 1 ? null : () => _popToBreadcrumb(i),
                child: DText(
                  crumbs[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color:
                      i == crumbs.length - 1
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _FolderDisplayItem item) {
    final theme = context.theme;
    final fileExists =
        !item.isFolder && item.path.isNotEmpty && storedFileExists(item.path);

    final bool anyFileExists;
    if (item.isFolder) {
      anyFileExists =
          widget.items.any(
            (i) =>
                _isInside(item.name, i) &&
                i.path.isNotEmpty &&
                storedFileExists(i.path),
          );
    } else {
      anyFileExists = fileExists;
    }
    final isDisabled = !anyFileExists;
    final canOpen = fileExists && !isDangerousFileName(item.name);

    return DItem(
      disabled: isDisabled,
      padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
      prefix: FileThumbnail(
        path: item.path,
        name: item.name,
        isDirectory: item.isFolder,
        size: 48,
        borderRadius: 6,
        iconColor: theme.colors.primary,
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      description: Text(appDataUnit.value.formatSize(item.sizeBytes)),
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
              : null,
      onPressed:
          item.isFolder
              ? () => _openFolder(item.name)
              : canOpen
              ? () => openStoredFile(item.path)
              : null,
    );
  }

  void _openFolder(String folderName) {
    final subItems = _filterSubItems(folderName);
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder:
            (_) => FolderDetails(
              title: folderName,
              items: subItems,
              directionLabel: widget.directionLabel,
              isSending: widget.isSending,
              breadcrumb: [
                ...widget.breadcrumb.isEmpty
                    ? [widget.title]
                    : widget.breadcrumb,
                folderName,
              ],
            ),
      ),
    );
  }

  List<FolderContentItem> _filterSubItems(String folderName) {
    return widget.items
        .where((item) => _isInside(folderName, item))
        .map((item) => _createSubItem(folderName, item))
        .toList();
  }

  bool _isInside(String folderName, FolderContentItem item) {
    final parts = _partsInsideRoot(item);
    return parts.isNotEmpty && parts.first == folderName;
  }

  FolderContentItem _createSubItem(String folderName, FolderContentItem item) {
    final raw = item.relativePath;
    final parts =
        raw == null || raw.trim().isEmpty
            ? [item.name]
            : raw
                .split(RegExp(r'[/\\]'))
                .where((p) => p.isNotEmpty)
                .toList();

    if (parts.isNotEmpty && parts.first == widget.title) {
      parts.removeAt(0);
    }
    if (parts.isNotEmpty && parts.first == folderName) {
      parts.removeAt(0);
    }

    return FolderContentItem(
      name: parts.isNotEmpty ? parts.last : item.name,
      path: item.path,
      sizeBytes: item.sizeBytes,
      relativePath: parts.join('/'),
      mimeWarning: item.mimeWarning,
    );
  }

  List<_FolderDisplayItem> _currentItems() {
    final folders = <String, List<FolderContentItem>>{};
    final files = <_FolderDisplayItem>[];

    for (final item in widget.items) {
      final parts = _partsInsideRoot(item);
      if (parts.isEmpty) continue;

      if (parts.length == 1) {
        files.add(_FolderDisplayItem.file(item, parts.first));
      } else {
        folders.putIfAbsent(parts.first, () => []).add(item);
      }
    }

    final folderItems =
        folders.entries.map((entry) {
          final children = entry.value;
          return _FolderDisplayItem.folder(
            name: entry.key,
            path: _folderPath(children.first, entry.key),
            sizeBytes: children.fold(0, (sum, item) => sum + item.sizeBytes),
          );
        }).toList();

    folderItems.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...folderItems, ...files];
  }

  List<String> _partsInsideRoot(FolderContentItem item) {
    final raw = item.relativePath;
    final parts =
        raw == null || raw.trim().isEmpty
            ? [item.name]
            : raw
                .split(RegExp(r'[/\\]'))
                .where((part) => part.isNotEmpty)
                .toList();
    if (parts.isNotEmpty && parts.first == widget.title) {
      return parts.skip(1).toList();
    }
    return parts;
  }

  String _folderPath(FolderContentItem item, String folderName) {
    if (item.path.isEmpty) return '';
    final parts = _partsInsideRoot(item);
    final folderIndex = parts.indexOf(folderName);
    if (folderIndex < 0) return '';

    var path = item.path;
    final levelsUp = parts.length - folderIndex - 1;
    for (var i = 0; i < levelsUp; i++) {
      path = p.dirname(path);
    }
    return path;
  }
}

class _FolderDisplayItem {
  const _FolderDisplayItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.isFolder,
    this.mimeWarning,
  });

  factory _FolderDisplayItem.file(FolderContentItem item, String name) =>
      _FolderDisplayItem(
        name: name,
        path: item.path,
        sizeBytes: item.sizeBytes,
        isFolder: false,
        mimeWarning: item.mimeWarning,
      );

  factory _FolderDisplayItem.folder({
    required String name,
    required String path,
    required int sizeBytes,
  }) => _FolderDisplayItem(
    name: name,
    path: path,
    sizeBytes: sizeBytes,
    isFolder: true,
  );

  final String name;
  final String path;
  final int sizeBytes;
  final bool isFolder;
  final String? mimeWarning;
}

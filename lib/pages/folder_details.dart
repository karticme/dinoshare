import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
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
    this.directionLabel,
    this.isSending = false,
  });

  final String title;
  final List<FolderContentItem> items;
  final String? directionLabel;
  final bool isSending;

  @override
  State<FolderDetails> createState() => _FolderDetailsState();
}

class _FolderDetailsState extends State<FolderDetails> {
  late List<String> _path;

  @override
  void initState() {
    super.initState();
    _path = const [];
  }

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
            title: _path.isEmpty ? widget.title : _path.last,
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
                      DItem(
                        spacing: 6,
                        minHeight: 32,
                        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                        backgroundColor: theme.colors.secondary,
                        prefix: HugeIcon(
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
                        title: DText(
                          widget.directionLabel!,
                          size: DTextSize.sm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          weight: FontWeight.w400,
                        ),
                      ),
                    _buildBreadcrumb(theme),
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
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(FThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: FBreadcrumb(
          children: [
            FBreadcrumbItem(
              current: _path.isEmpty,
              onPress:
                  _path.isEmpty ? null : () => setState(() => _path = const []),
              child: DText(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color:
                    _path.isEmpty
                        ? theme.colors.foreground
                        : theme.colors.mutedForeground,
              ),
            ),
            for (var i = 0; i < _path.length; i++)
              FBreadcrumbItem(
                current: i == _path.length - 1,
                onPress:
                    i == _path.length - 1
                        ? null
                        : () =>
                            setState(() => _path = _path.take(i + 1).toList()),
                child: DText(
                  _path[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color:
                      i == _path.length - 1
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
    final canOpen =
        !item.isFolder &&
        item.path.isNotEmpty &&
        storedFileExists(item.path) &&
        !isDangerousFileName(item.name);

    return DItem(
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
              ? () => setState(() => _path = [..._path, item.name])
              : canOpen
              ? () => openStoredFile(item.path)
              : null,
    );
  }

  List<_FolderDisplayItem> _currentItems() {
    final folders = <String, List<FolderContentItem>>{};
    final files = <_FolderDisplayItem>[];

    for (final item in widget.items) {
      final parts = _partsInsideRoot(item);
      if (parts.length <= _path.length) continue;
      if (!_matchesCurrentPath(parts)) continue;

      final nextPart = parts[_path.length];
      if (parts.length == _path.length + 1) {
        files.add(_FolderDisplayItem.file(item, nextPart));
      } else {
        folders.putIfAbsent(nextPart, () => []).add(item);
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

  bool _matchesCurrentPath(List<String> parts) {
    if (parts.length <= _path.length) return false;
    for (var i = 0; i < _path.length; i++) {
      if (parts[i] != _path[i]) return false;
    }
    return true;
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

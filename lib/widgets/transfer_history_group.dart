import 'package:dinoshare/style/typography.dart';
import 'package:flutter/widgets.dart';
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

    return DItemList(
      spacing: 2,
      borderRadius: BorderRadius.circular(14),
      children: [
        _buildDirectionItem(theme),
        for (final file in files) _buildFileItem(theme, file),
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

  Widget _buildFileItem(FThemeData theme, HistoryFileItem file) {
    final fileExists = file.path.isNotEmpty && storedFileExists(file.path);

    return DItem(
      padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
      spacing: 12,
      prefix: _buildFilePreview(theme, file),
      title: DText(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        weight: FontWeight.w500,
      ),
      description: DText(
        appDataUnit.value.formatSize(file.sizeBytes),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        color: theme.colors.mutedForeground,
        weight: FontWeight.w400,
      ),
      onPressed: fileExists ? () => openStoredFile(file.path) : null,
    );
  }

  Widget _buildFilePreview(FThemeData theme, HistoryFileItem file) {
    if (file.path.isNotEmpty && storedFileExists(file.path)) {
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
          icon: icon.icon.icon,
          color: theme.colors.primary,
          size: 28,
        ),
      ),
    );
  }
}

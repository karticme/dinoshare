import 'package:dinoshare/style/typography.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';

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

    return Container(
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
                child: Text('Done'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
            title: isStopped ? 'Stopped' : 'Completed',
          ),
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
                      session.completedItems
                          .map((item) => _buildFileItem(theme, unit, item))
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
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
    FThemeData theme,
    DataUnitType unit,
    TransferCompletedItem item,
  ) {
    final canOpen =
        storedFileExists(item.path) && !isDangerousFileName(item.name);

    return DItem(
      padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
      prefix: FileThumbnail(
        path: item.path,
        name: item.name,
        size: 48,
        borderRadius: 8,
        iconColor: theme.colors.primary,
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      description: Text(unit.formatSize(item.sizeBytes)),
      suffix:
          item.mimeWarning != null
              ? HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                size: 18,
                color: theme.colors.destructive,
              )
              : null,
      onPressed: canOpen ? () => openStoredFile(item.path) : null,
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

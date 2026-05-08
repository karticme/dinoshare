import 'dart:io';

import 'package:dinoshare/style/typography.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/transfer_history_group.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      color: theme.colors.secondary,
      child: Column(
        children: [
          DHeader(
            nested: true,
            prefix: [
              DButton(
                size: Platform.isMacOS ? DButtonSize.sm : DButtonSize.md,
                variant: DButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: Platform.isMacOS ? 20 : 24,
                ),
              ),
            ],
            title: 'History',
          ),
          Expanded(
            child: ValueListenableBuilder<List<TransferHistoryItem>>(
              valueListenable: appTransferHistory,
              builder: (_, history, _) {
                if (history.isEmpty) {
                  return _buildEmptyState(theme);
                }

                final groups = _groupHistory(history);
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    Platform.isAndroid ? 24 : 16,
                  ),
                  children: [
                    for (final group in groups) ...[
                      _buildSectionHeader(theme, group.label),
                      Column(
                        spacing: 8,
                        children: group.items.map(_buildHistoryGroup).toList(),
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: DButton(
                        variant: DButtonVariant.destructive,
                        size: DButtonSize.sm,
                        onPressed: clearTransferHistory,
                        child: Text('Delete History'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Container(
            width: 52,
            height: 52,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colors.border.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedClipboardClock,
                size: 24,
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          DText('No Transfer History', color: theme.colors.mutedForeground),
          SizedBox(height: 48),
        ],
      ),
    );
  }

  List<_HistoryGroup> _groupHistory(List<TransferHistoryItem> history) {
    final sorted = [...history]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final groups = <_HistoryGroup>[];

    for (final item in sorted) {
      final label = _sectionLabel(item.completedAt);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(_HistoryGroup(label, [item]));
      } else {
        groups.last.items.add(item);
      }
    }

    return groups;
  }

  Widget _buildSectionHeader(FThemeData theme, String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        label,
        style: theme.typography.sm.copyWith(
          color: theme.colors.secondaryForeground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildHistoryGroup(TransferHistoryItem h) {
    return TransferHistoryGroupView(item: h);
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return 'Today';

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    if (isYesterday) return 'Yesterday';

    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final sameYear = date.year == now.year;
    if (sameYear) return '${_monthName(date.month)} ${date.day}';
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

class _HistoryGroup {
  _HistoryGroup(this.label, this.items);

  final String label;
  final List<TransferHistoryItem> items;
}

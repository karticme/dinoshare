import 'dart:io';
import 'package:dinoshare/style/svgs.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/util/utility_function.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/widgets/big_button.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/transfer_history_group.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/pages/history.dart';
import 'package:dinoshare/pages/settings.dart';
import 'package:dinoshare/pages/share.dart';
import 'package:dinoshare/pages/receive.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Good Morning';
  if (hour >= 12 && hour < 17) return 'Good Afternoon';
  if (hour >= 17 && hour < 21) return 'Good Evening';
  return 'Have a good night !';
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    return Container(
      color: theme.colors.secondary,
      child: Column(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  border: Border(
                    bottom: BorderSide(color: theme.colors.border),
                  ),
                ),
                child: Column(
                  children: [
                    DHeader(
                      suffix: [
                        DButton(
                          size:
                              Platform.isMacOS
                                  ? DButtonSize.sm
                                  : DButtonSize.md,
                          variant: DButtonVariant.ghost,
                          onPressed:
                              () => Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) => const Settings(),
                                ),
                              ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSettings01,
                            size: Platform.isMacOS ? 20 : 24,
                          ),
                        ),
                      ],
                      title: getGreeting(),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(
                        16,
                        isDesktop() ? 0 : 8,
                        16,
                        16,
                      ),
                      child: Row(
                        spacing: 16,
                        children: [
                          Expanded(
                            child: DBigButton(
                              label: 'Share',
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedShare03,
                              ),
                              onPressed: () async {
                                await pickShareTargets(reset: true);
                                if (!context.mounted) return;
                                if (appShareItems.value.isEmpty) return;
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (_) => const Share(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: DBigButton(
                              variant: DBigButtonVariant.outline,
                              label: 'Receive',
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedDownload02,
                              ),
                              onPressed:
                                  () => Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (_) => const Receive(),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder<List<TransferHistoryItem>>(
              valueListenable: appTransferHistory,
              builder: (_, history, _) {
                final recent =
                    history.where((h) => _isToday(h.completedAt)).toList()
                      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
                final recentToday = recent.take(5).toList();

                final deviceChip = ValueListenableBuilder<String>(
                  valueListenable: appDeviceName,
                  builder:
                      (_, name, _) => ValueListenableBuilder<String>(
                        valueListenable: appDeviceTypeLabel,
                        builder:
                            (_, typeLabel, _) => DItem(
                              prefix: HugeIcon(
                                icon: _deviceIcon(typeLabel),
                                color: lCustom.success,
                                size: 20,
                              ),
                              suffix: DText(
                                typeLabel,
                                size: DTextSize.sm,
                                color: theme.colors.mutedForeground,
                              ),
                              title: Text(name),
                            ),
                      ),
                );

                final favouriteChip = DItem(
                  prefix: SvgPicture.string(filledStar, width: 20, height: 20),
                  title: Text("Favourite Devices"),
                );

                final historyHeader = Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DText(
                        'History',
                        weight: FontWeight.w600,
                        color: theme.colors.mutedForeground,
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap:
                              () => Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) => const History(),
                                ),
                              ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: DText(
                              'View All',
                              size: DTextSize.sm,
                              color: lCustom.info,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                final footer = [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(24, 40, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          spacing: 8,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DText(
                              'Made with',
                              size: DTextSize.h2,
                              color: theme.colors.mutedForeground,
                            ),
                            SvgPicture.string(redHeart, width: 20, height: 20),
                          ],
                        ),
                        DText(
                          'v1.0.0',
                          size: DTextSize.sm,
                          color: theme.colors.mutedForeground.withAlpha(180),
                        ),
                      ],
                    ),
                  ),
                ];

                // Empty state
                if (recentToday.isEmpty) {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(16, 16, 16, 0),
                        child: DItemList(
                          borderRadius: BorderRadius.circular(14),
                          children: [deviceChip, favouriteChip],
                        ),
                      ),
                      historyHeader,
                      Expanded(
                        child: Center(
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
                              DText(
                                'No Transfers Today',
                                color: theme.colors.mutedForeground,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...footer,
                    ],
                  );
                }

                // History + scroll
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: deviceChip),
                    SliverToBoxAdapter(child: historyHeader),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          spacing: 8,
                          children:
                              recentToday
                                  .map((h) => TransferHistoryGroupView(item: h))
                                  .toList(),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: footer,
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<List<dynamic>> _deviceIcon(String typeLabel) {
    final l = typeLabel.toLowerCase();
    if (l.contains('macbook') || l.contains('laptop')) {
      return HugeIcons.strokeRoundedLaptop;
    }
    if (l.contains('imac') ||
        l.contains('mac mini') ||
        l.contains('mac pro') ||
        l.contains('mac studio') ||
        l.contains('windows') ||
        l.contains('linux') ||
        l.contains('desktop')) {
      return HugeIcons.strokeRoundedComputer;
    }
    if (l.contains('ipad') || l.contains('tablet')) {
      return HugeIcons.strokeRoundedTablet01;
    }
    return HugeIcons.strokeRoundedSmartPhone02;
  }
}

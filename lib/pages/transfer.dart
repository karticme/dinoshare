import 'dart:io';

import 'package:dinoshare/style/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/pages/transfer_done.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/circular_progress.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/progress_bar.dart';

class Transfer extends StatefulWidget {
  const Transfer({super.key, required this.role});

  final TransferRole role;

  @override
  State<Transfer> createState() => _TransferState();
}

class _TransferState extends State<Transfer> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    transferService.activeSession.addListener(_onSessionChanged);
    appDataUnit.addListener(_onUnitChanged);
  }

  @override
  void dispose() {
    transferService.activeSession.removeListener(_onSessionChanged);
    appDataUnit.removeListener(_onUnitChanged);
    super.dispose();
  }

  void _onUnitChanged() => setState(() {});

  void _onSessionChanged() {
    final session = transferService.activeSession.value;
    if (session == null) return;
    if (_navigated) return;
    final shouldStayOnStoppedTransfer =
        session.status == TransferStatus.stopped &&
        session.completedItems.isEmpty;
    if (shouldStayOnStoppedTransfer) return;
    if (session.status == TransferStatus.completed ||
        session.status == TransferStatus.stopped ||
        session.status == TransferStatus.failed) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => TransferDone(session: session)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ValueListenableBuilder<TransferSession?>(
      valueListenable: transferService.activeSession,
      builder: (_, session, _) {
        final title =
            widget.role == TransferRole.sending ? 'Sharing' : 'Receiving';
        final totalBytes = session?.totalBytes ?? 0;
        final transferred = session?.bytesTransferred ?? 0;
        final speedBps = session?.currentSpeedBytesPerSec ?? 0.0;
        final etaSecs = session?.estimatedSecondsRemaining;
        final currentFile = session?.currentFile ?? '';
        final isStopped = session?.status == TransferStatus.stopped;
        final progressPct =
            totalBytes == 0
                ? 0.0
                : (transferred / totalBytes * 100).clamp(0.0, 100.0);

        final speedLabel = appDataUnit.value.formatSpeed(speedBps);
        final transferredLabel = appDataUnit.value.formatSize(transferred);
        final totalLabel = appDataUnit.value.formatSize(totalBytes);
        final progressLabel = '$transferredLabel / $totalLabel';
        final etaLabel =
            etaSecs == null
                ? '—'
                : etaSecs < 60
                ? 'ETA ${etaSecs}s'
                : 'ETA ${(etaSecs / 60).ceil()}m';

        return Container(
          color: theme.colors.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DHeader(
                nested: true,
                suffix: [
                  if (!isStopped)
                    DButton(
                      size: DButtonSize.xs,
                      variant: DButtonVariant.destructive,
                      child: Text('Stop'),
                      onPressed: () => transferService.stopActiveTransfer(),
                    )
                  else
                    DButton(
                      size: DButtonSize.xs,
                      variant: DButtonVariant.ghost,
                      child: Text('Done'),
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst),
                    ),
                ],
                title: title,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DText(
                            speedLabel,
                            color: theme.colors.secondaryForeground,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          DText(
                            etaLabel,
                            color: theme.colors.secondaryForeground,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ],
                      ),
                    ),
                    DProgressbar(value: progressPct, label: progressLabel),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: DText(
                        currentFile.isEmpty ? 'NA' : currentFile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (isStopped)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildStopBanner(
                    theme,
                    session?.error ?? 'Transfer stopped',
                  ),
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
                          session == null
                              ? []
                              : session.allItems
                                  .map(
                                    (item) => _buildFileItem(
                                      context,
                                      theme,
                                      item,
                                      session,
                                    ),
                                  )
                                  .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    FThemeData theme,
    TransferItemProgress item,
    TransferSession session,
  ) {
    final isCompleted = item.isCompleted;
    final isInProgress = !isCompleted && item.bytesTransferred > 0;
    final isPending = !isCompleted && !isInProgress;

    // Find the completed item path for clickable items
    TransferCompletedItem? completedItem;
    if (isCompleted) {
      try {
        completedItem = session.completedItems.firstWhere(
          (c) => c.topLevelName == item.name || c.name == item.name,
        );
      } catch (_) {}
    }

    final canOpen =
        isCompleted &&
        completedItem?.path != null &&
        storedFileExists(completedItem!.path) &&
        !isDangerousFileName(item.name);
    final previewPath = completedItem?.path ?? item.path ?? '';
    final previewName = completedItem?.name ?? item.name;
    final canShowPreview =
        previewPath.isNotEmpty &&
        (session.role == TransferRole.sending || completedItem != null);

    return DItem(
      disabled: isPending,
      padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
      prefix: FileThumbnail(
        path: previewPath,
        name: previewName,
        isDirectory: _isDirectoryPath(previewPath),
        size: 48,
        borderRadius: 6,
        showThumbnail: canShowPreview,
        iconColor: theme.colors.primary,
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      description: Text(appDataUnit.value.formatSize(item.sizeBytes)),
      suffix:
          isInProgress
              ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: DCircularProgress(value: item.progress * 100, size: 24),
              )
              : null,
      onPressed: canOpen ? () => openStoredFile(completedItem!.path) : null,
    );
  }

  bool _isDirectoryPath(String path) {
    if (path.isEmpty) return false;
    try {
      return Directory(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  Widget _buildStopBanner(FThemeData theme, String message) {
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
          Expanded(child: DText(message, color: theme.colors.destructive)),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:dinoshare/style/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/pages/transfer.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/share_target_picker_sheet.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/util/fomart_icon.dart';

class Share extends StatefulWidget {
  const Share({super.key});

  @override
  State<Share> createState() => _ShareState();
}

class _ShareState extends State<Share> {
  @override
  void initState() {
    super.initState();
    appShareItems.addListener(_onItemsChanged);
  }

  @override
  void dispose() {
    appShareItems.removeListener(_onItemsChanged);
    super.dispose();
  }

  void _onItemsChanged() {
    if (appShareItems.value.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );
    final desktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

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
            title: 'Share',
          ),
          Expanded(
            child: ValueListenableBuilder<List<SelectedShareItem>>(
              valueListenable: appShareItems,
              builder:
                  (_, items, _) => ListView(
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 24,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Padding(
                                  padding: EdgeInsetsGeometry.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    0,
                                  ),
                                  child: DText(
                                    'Selected Files',
                                    weight: FontWeight.w500,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                DItemList(
                                  borderRadius: BorderRadius.circular(14),
                                  children:
                                      items
                                          .map(
                                            (item) => DItem(
                                              prefix: HugeIcon(
                                                icon:
                                                    item.isText
                                                        ? HugeIcons
                                                            .strokeRoundedTextFont
                                                        : item.isDirectory
                                                        ? HugeIcons
                                                            .strokeRoundedFolder01
                                                        : fileTypeIconData(
                                                          item.name,
                                                        ).icon.icon,
                                                size: 20,
                                                color: theme.colors.primary,
                                                strokeWidth: 2,
                                              ),
                                              title: Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              suffix:
                                                  item.isSent
                                                      ? HugeIcon(
                                                        icon:
                                                            HugeIcons
                                                                .strokeRoundedTick02,
                                                        size: 16,
                                                        color: lCustom.success,
                                                        strokeWidth: 2,
                                                      )
                                                      : GestureDetector(
                                                        onTap:
                                                            () =>
                                                                removeShareTarget(
                                                                  item.id,
                                                                ),
                                                        child: HugeIcon(
                                                          icon:
                                                              HugeIcons
                                                                  .strokeRoundedCancel01,
                                                          size: 16,
                                                          color: lCustom.ring,
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: desktop ? 16 : 20,
            ),
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(
                top: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            child: Row(
              spacing: 20,
              children: [
                Expanded(
                  child: DButton(
                    variant: DButtonVariant.outline,
                    prefix: HugeIcon(icon: HugeIcons.strokeRoundedPlusSign),
                    child: Text('Add Files'),
                    onPressed:
                        () => showShareTargetPickerSheet(context, reset: false),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<List<SelectedShareItem>>(
                    valueListenable: appShareItems,
                    builder:
                        (_, items, _) => DButton(
                          onPressed:
                              items.isEmpty
                                  ? null
                                  : () => _openDeviceSheet(context),
                          child: Text('Continue'),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDeviceSheet(BuildContext context) {
    final items = appShareItems.value;
    final sentTextItemId =
        items.length == 1 && items.first.isText ? items.first.id : null;
    showFSheet(
      side: FLayout.btt,
      context: context,
      mainAxisMaxRatio: null,
      style: FModalSheetStyleDelta.delta(
        barrierFilter:
            (animation) => ImageFilter.compose(
              outer: ImageFilter.blur(
                sigmaX: animation * 5,
                sigmaY: animation * 5,
              ),
              inner: ColorFilter.mode(
                context.theme.colors.barrier,
                BlendMode.srcOver,
              ),
            ),
      ),
      builder:
          (sheetCtx) => _DevicePickerSheet(
            parentContext: context,
            sentTextItemId: sentTextItemId,
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DevicePickerSheet extends StatefulWidget {
  const _DevicePickerSheet({
    required this.parentContext,
    required this.sentTextItemId,
  });

  final BuildContext parentContext;
  final String? sentTextItemId;

  @override
  State<_DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<_DevicePickerSheet>
    with WidgetsBindingObserver {
  String? _pendingPeerId;
  bool _navigated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    transferService.startDiscovery();
    transferService.activeSession.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    transferService.activeSession.removeListener(_onSessionChanged);
    transferService.stopDiscovery();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      transferService.startDiscovery();
    }
  }

  void _onSessionChanged() {
    final session = transferService.activeSession.value;
    if (session == null || _navigated) return;
    if (session.role != TransferRole.sending) return;

    if (session.status == TransferStatus.inProgress) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(widget.parentContext).pushReplacement(
          CupertinoPageRoute(
            builder: (_) => Transfer(role: TransferRole.sending),
          ),
        );
      });
    } else if (session.status == TransferStatus.rejected ||
        session.status == TransferStatus.failed) {
      final msg =
          session.status == TransferStatus.rejected
              ? 'Receiver declined the transfer.'
              : (session.error ?? 'Transfer failed.');
      if (mounted) {
        setState(() {
          _pendingPeerId = null;
          _errorMessage = msg;
        });
      }
    }
  }

  Future<void> _selectPeer(PeerDevice peer) async {
    setState(() {
      _pendingPeerId = peer.id;
      _errorMessage = null;
    });
    final selection = currentSelection();
    final isTextOnly = selection.files.every((file) => file.isText);
    final status = await transferService.sendTransferRequest(
      peer: peer,
      selection: selection,
      senderName: appDeviceName.value,
    );
    if (!mounted) return;
    if (isTextOnly && status == TransferStatus.completed) {
      if (widget.sentTextItemId != null) {
        markShareTargetSent(widget.sentTextItemId!);
      }
      Navigator.of(context).pop();
      return;
    }
    if (isTextOnly && status == TransferStatus.rejected) {
      setState(() {
        _pendingPeerId = null;
        _errorMessage = 'Receiver declined the transfer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder:
          (ctx, controller) => ScrollConfiguration(
            behavior: ScrollConfiguration.of(ctx).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: theme.colors.border,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          spacing: 16,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                spacing: 8,
                                children: [
                                  FCircularProgress.loader(),
                                  DText(
                                    _pendingPeerId != null
                                        ? 'Waiting for receiver…'
                                        : 'Searching for devices',
                                    color: theme.colors.foreground,
                                  ),
                                ],
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    DText(
                                      _errorMessage!,
                                      color: theme.colors.destructive,
                                    ),
                                  ],
                                ),
                              ),
                            ValueListenableBuilder<List<PeerDevice>>(
                              valueListenable: transferService.discoveredPeers,
                              builder: (_, peers, _) {
                                if (peers.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: DText(
                                      'No devices found nearby.\n\nMake sure the other device is on\nthe same Wi-Fi.',
                                      textAlign: TextAlign.center,
                                      color: theme.colors.mutedForeground,
                                    ),
                                  );
                                }
                                return DItemList(
                                  borderRadius: BorderRadius.circular(14),
                                  children:
                                      peers.map((peer) {
                                        final isLoading =
                                            _pendingPeerId == peer.id;
                                        final isDisabled =
                                            _pendingPeerId != null &&
                                            _pendingPeerId != peer.id;
                                        return DItem(
                                          disabled: isDisabled,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 12,
                                          ),
                                          title: Text(peer.name),
                                          description: Text(
                                            _deviceTypeLabel(peer.deviceType),
                                          ),
                                          prefix: HugeIcon(
                                            icon: _deviceTypeIcon(
                                              peer.deviceType,
                                            ),
                                            size: 28,
                                            color: theme.colors.primary,
                                          ),
                                          suffix:
                                              isLoading
                                                  ? FCircularProgress.loader(
                                                    size:
                                                        FCircularProgressSizeVariant
                                                            .md,
                                                  )
                                                  : null,
                                          onPressed:
                                              (isLoading || isDisabled)
                                                  ? null
                                                  : () => _selectPeer(peer),
                                        );
                                      }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _deviceTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'macos':
        return 'Mac';
      case 'windows':
        return 'Windows PC';
      case 'linux':
        return 'Linux';
      case 'ios':
        return 'iPhone';
      case 'android':
        return 'Android';
      default:
        return 'Device';
    }
  }

  List<List<dynamic>> _deviceTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'macos':
      case 'windows':
      case 'linux':
        return HugeIcons.strokeRoundedLaptop;
      case 'ios':
        return HugeIcons.strokeRoundedSmartPhone01;
      case 'android':
      default:
        return HugeIcons.strokeRoundedSmartPhone02;
    }
  }
}

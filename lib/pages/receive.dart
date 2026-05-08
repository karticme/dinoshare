import 'dart:io';

import 'package:dinoshare/pages/transfer.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/device_wait.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/stacked_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

class Receive extends StatefulWidget {
  const Receive({super.key});

  @override
  State<Receive> createState() => _ReceiveState();
}

class _ReceiveState extends State<Receive> with WidgetsBindingObserver {
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!appAlwaysReceive.value) {
      transferService.startReceiver(deviceName: appDeviceName.value);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!appAlwaysReceive.value) {
      transferService.stopReceiver();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        !appAlwaysReceive.value) {
      transferService.startReceiver(deviceName: appDeviceName.value);
    }
  }

  Future<void> _accept(IncomingTransferRequest request) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final ok = await transferService.respondToIncoming(
      sessionId: request.sessionId,
      accept: true,
    );
    if (!mounted) return;
    setState(() => _accepting = false);
    if (ok) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => Transfer(role: TransferRole.receiving),
        ),
      );
    }
  }

  Future<void> _reject(IncomingTransferRequest request) async {
    await transferService.respondToIncoming(
      sessionId: request.sessionId,
      accept: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      color: theme.colors.secondary,
      child: Stack(
        children: [
          Column(
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
                title: 'Receive',
              ),
              Expanded(child: _ReceiveWaitingBody(theme: theme)),
            ],
          ),
          ValueListenableBuilder<IncomingTransferRequest?>(
            valueListenable: transferService.incomingRequest,
            builder: (_, request, _) {
              if (request == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: StackedDialog(
                  children: [_buildRequestDialog(theme, request)],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDialog(
    FThemeData theme,
    IncomingTransferRequest request,
  ) {
    final custom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );
    final count =
        request.topLevelCount == 0
            ? request.files.length
            : request.topLevelCount;
    final fileLabel = '$count file${count == 1 ? '' : 's'}';
    final totalLabel = appDataUnit.value.formatSize(request.totalBytes);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.05),
            offset: const Offset(1, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Row(
            spacing: 12,
            children: [
              HugeIcon(
                icon: _deviceTypeIconFromRequest(request),
                size: 32,
                color: theme.colors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DText(
                      request.senderName,
                      size: DTextSize.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    DText(
                      _deviceTypeLabelFromRequest(request),
                      color: theme.colors.mutedForeground,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              DButton(
                size: DButtonSize.sm,
                variant: DButtonVariant.outline,
                child: HugeIcon(icon: HugeIcons.strokeRoundedStar, size: 20,),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: DText.rich(
              TextSpan(
                style: TextStyle(color: theme.colors.mutedForeground),
                children: [
                  TextSpan(text: '${request.senderName} wants to share '),
                  TextSpan(
                    text: fileLabel,
                    style: TextStyle(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' (Total $totalLabel).'),
                ],
              ),
            ),
          ),
          Row(
            spacing: 12,
            children: [
              DButton(
                size: DButtonSize.sm,
                variant: DButtonVariant.destructive,
                onPressed: _accepting ? null : () => _reject(request),
                prefix: HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                child: const Text('Reject'),
              ),
              Expanded(
                child: DButton(
                  size: DButtonSize.sm,
                  variant: DButtonVariant.success,
                  onPressed: _accepting ? null : () => _accept(request),
                  prefix:
                      _accepting
                          ? FCircularProgress.loader()
                          : HugeIcon(icon: HugeIcons.strokeRoundedTick02),
                  style: DButtonStyle(width: double.infinity),
                  textColor: custom.successForeground,
                  child: Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _deviceTypeLabelFromRequest(IncomingTransferRequest request) {
    return 'Device';
  }

  List<List<dynamic>> _deviceTypeIconFromRequest(
    IncomingTransferRequest request,
  ) {
    return HugeIcons.strokeRoundedLaptop;
  }
}

class _ReceiveWaitingBody extends StatelessWidget {
  final FThemeData theme;

  const _ReceiveWaitingBody({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        spacing: 40,
        children: [
          _ReceiveIdentity(theme: theme),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 352,
                height: 352,
                child: DeviceWait(
                  variant: DeviceWaitVariant.primary,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSmartPhone01,
                    color: theme.colors.primaryForeground,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          DText(
            'Wait for another\ndevice to share',
            color: theme.colors.mutedForeground.withValues(alpha: 0.5),
            weight: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReceiveIdentity extends StatelessWidget {
  final FThemeData theme;

  const _ReceiveIdentity({required this.theme});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appDeviceName,
      builder:
          (_, name, _) => Column(
            spacing: 4,
            children: [
              DText(
                name,
                size: DTextSize.h1,
                color: theme.colors.foreground,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DText(
                  _deviceTypeLabel(),
                  color: theme.colors.mutedForeground,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
    );
  }

  String _deviceTypeLabel() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isWindows) return 'Windows PC';
    return 'Device';
  }
}

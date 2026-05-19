import 'package:dinoshare/pages/transfer.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/svgs.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/stacked_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

class IncomingTransferOverlay extends StatefulWidget {
  const IncomingTransferOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<IncomingTransferOverlay> createState() =>
      _IncomingTransferOverlayState();
}

class _IncomingTransferOverlayState extends State<IncomingTransferOverlay> {
  bool _accepting = false;
  bool _starToggled = false;
  bool _navigatedToTransfer = false;

  @override
  void initState() {
    super.initState();
    transferService.incomingRequest.addListener(_onIncomingRequestChanged);
    transferService.activeSession.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    transferService.incomingRequest.removeListener(_onIncomingRequestChanged);
    transferService.activeSession.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onIncomingRequestChanged() {
    if (!mounted) return;

    setState(() {
      _accepting = false;
      _starToggled = false;
      _navigatedToTransfer = false;
    });
  }

  void _onSessionChanged() {
    final session = transferService.activeSession.value;
    if (session == null || _navigatedToTransfer) return;
    if (session.role != TransferRole.receiving) return;
    if (session.status != TransferStatus.inProgress) return;

    _navigatedToTransfer = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => Transfer(role: TransferRole.receiving),
        ),
      );
    });
  }

  Future<void> _accept(IncomingTransferRequest request) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final starToggled = _starToggled;
    final ok = await transferService.respondToIncoming(
      sessionId: request.sessionId,
      accept: true,
    );
    if (!mounted) return;
    setState(() => _accepting = false);
    if (ok && starToggled) {
      await addFavouriteDevice(
        FavouriteDevice(
          id: request.senderId,
          name: request.senderName,
          deviceType: request.senderDeviceType,
        ),
      );
    }
  }

  Future<void> _reject(IncomingTransferRequest request) async {
    if (_requestText(request) != null) {
      await transferService.respondToIncomingText(
        sessionId: request.sessionId,
        accept: false,
      );
    } else {
      await transferService.respondToIncoming(
        sessionId: request.sessionId,
        accept: false,
      );
    }
    if (!mounted) return;
    setState(() {
      _accepting = false;
      _starToggled = false;
    });
  }

  Future<void> _copyText(IncomingTransferRequest request, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await transferService.respondToIncomingText(
      sessionId: request.sessionId,
      accept: true,
    );
  }

  void _toggleFavorite() {
    setState(() {
      _starToggled = !_starToggled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ValueListenableBuilder<IncomingTransferRequest?>(
      valueListenable: transferService.incomingRequest,
      builder: (_, request, child) {
        final base = child ?? const SizedBox.shrink();
        if (request == null) return base;

        return Stack(
          children: [
            base,
            Positioned.fill(
              child: StackedDialog(
                children: [_buildRequestDialog(theme, request)],
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _buildRequestDialog(
    FThemeData theme,
    IncomingTransferRequest request,
  ) {
    final text = _requestText(request);
    if (text != null) {
      return _buildTextRequestDialog(theme, request, text);
    }

    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );
    final count =
        request.topLevelCount == 0
            ? request.files.length
            : request.topLevelCount;
    final fileLabel = _requestItemLabel(request, count);
    final totalLabel = appDataUnit.value.formatSize(request.totalBytes);
    final alreadyFavorite = isFavouriteDevice(request.senderId);

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
                variant: DButtonVariant.ghost,
                onPressed: _toggleFavorite,
                child:
                    _starToggled || alreadyFavorite
                        ? SvgPicture.string(filledStar, width: 20, height: 20)
                        : HugeIcon(
                          icon: HugeIcons.strokeRoundedStar,
                          size: 20,
                          strokeWidth: 1.5,
                          color: lCustom.success,
                        ),
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
                  textColor: lCustom.successForeground,
                  child: Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextRequestDialog(
    FThemeData theme,
    IncomingTransferRequest request,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        spacing: 14,
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
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: DText(
              '${request.senderName} shared a text.',
              color: theme.colors.mutedForeground,
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 230),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colors.border),
            ),
            child: SingleChildScrollView(
              child: DText(text, color: theme.colors.mutedForeground),
            ),
          ),
          Row(
            spacing: 10,
            children: [
              DButton(
                size: DButtonSize.sm,
                variant: DButtonVariant.destructive,
                onPressed: () => _reject(request),
                prefix: HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                child: const Text('Reject'),
              ),
              Expanded(
                child: DButton(
                  size: DButtonSize.sm,
                  variant: DButtonVariant.outline,
                  onPressed: () => _copyText(request, text),
                  prefix: HugeIcon(icon: HugeIcons.strokeRoundedCopy01),
                  style: DButtonStyle(width: double.infinity),
                  child: const Text('Copy'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _requestItemLabel(IncomingTransferRequest request, int fallbackCount) {
    final groups = <String, List<TransferFileEntry>>{};
    for (final file in request.files) {
      groups.putIfAbsent(file.topLevelName, () => []).add(file);
    }

    if (groups.isEmpty) {
      return '$fallbackCount file${fallbackCount == 1 ? '' : 's'}';
    }

    var folderCount = 0;
    var fileCount = 0;
    for (final group in groups.values) {
      final first = group.first;
      final isFolder =
          first.isTopLevelDirectory ||
          group.length > 1 ||
          first.relativePath != first.topLevelName;
      if (isFolder) {
        folderCount++;
      } else {
        fileCount++;
      }
    }

    if (folderCount == 0) {
      return '$fileCount file${fileCount == 1 ? '' : 's'}';
    }
    if (fileCount == 0) {
      return '$folderCount folder${folderCount == 1 ? '' : 's'}';
    }
    return '$fileCount file${fileCount == 1 ? '' : 's'} and '
        '$folderCount folder${folderCount == 1 ? '' : 's'}';
  }

  String? _requestText(IncomingTransferRequest request) {
    for (final file in request.files) {
      if (file.isText && file.textContent != null) return file.textContent;
    }
    return null;
  }

  String _deviceTypeLabelFromRequest(IncomingTransferRequest request) {
    switch (request.senderDeviceType?.toLowerCase()) {
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

  List<List<dynamic>> _deviceTypeIconFromRequest(
    IncomingTransferRequest request,
  ) {
    switch (request.senderDeviceType?.toLowerCase()) {
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

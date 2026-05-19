import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

void showShareTargetPickerSheet(
  BuildContext context, {
  required bool reset,
  VoidCallback? onPicked,
}) {
  showFSheet(
    side: FLayout.btt,
    context: context,
    mainAxisMaxRatio: null,
    builder: (ctx) {
      final theme = ctx.theme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.6,
        maxChildSize: 0.8,
        builder:
            (sheetCtx, controller) => Container(
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
                spacing: 12,
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
                    child: ListView(
                      controller: controller,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(8, 4, 8, 8),
                          child: DText(
                            'Choose a Type',
                            weight: FontWeight.w500,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: DItemList(
                            borderRadius: BorderRadius.circular(14),
                            children: [
                              _ShareTargetOption(
                                title: 'Images / Videos / Files / Etc',
                                icon: HugeIcons.strokeRoundedFile01,
                                onPressed:
                                    () => _pick(
                                      sheetCtx,
                                      reset: reset,
                                      type: ShareTargetType.file,
                                      onPicked: onPicked,
                                    ),
                              ),
                              _ShareTargetOption(
                                title: 'Folder(s)',
                                icon: HugeIcons.strokeRoundedFolder01,
                                onPressed:
                                    () => _pick(
                                      sheetCtx,
                                      reset: reset,
                                      type: ShareTargetType.folder,
                                      onPicked: onPicked,
                                    ),
                              ),
                              _ShareTargetOption(
                                title: 'Text',
                                icon: HugeIcons.strokeRoundedTextFont,
                                onPressed:
                                    () => _openTextSheet(
                                      context,
                                      sheetCtx,
                                      reset: reset,
                                      onPicked: onPicked,
                                    ),
                              ),
                              _ShareTargetOption(
                                title: 'Paste Text',
                                icon: HugeIcons.strokeRoundedClipboardPaste,
                                onPressed:
                                    () => _pasteText(
                                      sheetCtx,
                                      reset: reset,
                                      onPicked: onPicked,
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
            ),
      );
    },
  );
}

void _openTextSheet(
  BuildContext parentContext,
  BuildContext sheetContext, {
  required bool reset,
  VoidCallback? onPicked,
}) {
  Navigator.of(sheetContext).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showFSheet(
      side: FLayout.btt,
      context: parentContext,
      mainAxisMaxRatio: null,
      builder: (ctx) => _TextShareSheet(reset: reset, onPicked: onPicked),
    );
  });
}

Future<void> _pasteText(
  BuildContext sheetContext, {
  required bool reset,
  VoidCallback? onPicked,
}) async {
  Navigator.of(sheetContext).pop();
  final added = await addClipboardTextShareTarget(reset: reset);
  if (added) onPicked?.call();
}

Future<void> _pick(
  BuildContext sheetContext, {
  required bool reset,
  required ShareTargetType type,
  VoidCallback? onPicked,
}) async {
  Navigator.of(sheetContext).pop();
  await pickShareTargets(reset: reset, type: type);
  onPicked?.call();
}

class _ShareTargetOption extends StatelessWidget {
  const _ShareTargetOption({
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final List<List<dynamic>> icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return DItem(
      title: Text(title),
      prefix: HugeIcon(icon: icon, size: 24, color: theme.colors.primary),
      onPressed: onPressed,
    );
  }
}

class _TextShareSheet extends StatefulWidget {
  const _TextShareSheet({required this.reset, this.onPicked});

  final bool reset;
  final VoidCallback? onPicked;

  @override
  State<_TextShareSheet> createState() => _TextShareSheetState();
}

class _TextShareSheetState extends State<_TextShareSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final added = await addTextShareTarget(
      text: _controller.text,
      reset: widget.reset,
    );
    if (!mounted) return;
    if (!added) return;
    Navigator.of(context).pop();
    widget.onPicked?.call();
  }

  void _clear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: theme.colors.border,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            Container(
              width: 52,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DText(
                  'Text',
                  weight: FontWeight.w500,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            CupertinoTextField(
              controller: _controller,
              placeholder: 'Write here ...',
              minLines: 9,
              maxLines: 9,
              maxLength: 5000,
              padding: const EdgeInsets.all(16),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: BoxDecoration(
                color: theme.colors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colors.border),
              ),
              style: TextStyle(color: theme.colors.foreground),
              placeholderStyle: TextStyle(color: theme.colors.mutedForeground),
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: DButton(
                    variant: DButtonVariant.outline,
                    onPressed: _clear,
                    child: Text(
                      'Clear',
                      style: TextStyle(color: theme.colors.destructive),
                    ),
                  ),
                ),
                Expanded(
                  child: DButton(
                    variant: DButtonVariant.success,
                    onPressed: _done,
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

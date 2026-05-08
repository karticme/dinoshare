import 'dart:io';
import 'dart:math' as math;

import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/util/utility_function.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class DHeader extends StatefulWidget {
  final String title;
  final List<Widget> prefix;
  final List<Widget> suffix;
  final bool nested;

  const DHeader({
    super.key,
    this.title = '',
    this.prefix = const [],
    this.suffix = const [],
    this.nested = false,
  });

  @override
  State<DHeader> createState() => _DHeaderState();
}

class _DHeaderState extends State<DHeader> with SingleTickerProviderStateMixin {
  final GlobalKey _prefixKey = GlobalKey();
  final GlobalKey _suffixKey = GlobalKey();
  double _sideWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_updateSideWidth);
  }

  @override
  void didUpdateWidget(covariant DHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_updateSideWidth);
  }

  void _updateSideWidth(Duration _) {
    if (!mounted || !widget.nested) return;
    final prefixContext = _prefixKey.currentContext;
    final suffixContext = _suffixKey.currentContext;
    if (prefixContext == null || suffixContext == null) return;
    final prefixWidth = prefixContext.size?.width ?? 0;
    final suffixWidth = suffixContext.size?.width ?? 0;
    final maxWidth = math.max(prefixWidth, suffixWidth);
    if ((maxWidth - _sideWidth).abs() > 0.5) {
      setState(() {
        _sideWidth = maxWidth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    Widget titleWidget = DText(
      widget.title,
      size:
          isDesktop()
              ? DTextSize.h3
              : widget.nested
              ? DTextSize.h1
              : DTextSize.title,
      color: theme.colors.secondaryForeground,
    );

    return Container(
      width: double.infinity,
      height:
          isDesktop()
              ? 56
              : Platform.isIOS
              ? 126
              : 112,
      padding: EdgeInsets.fromLTRB(
        Platform.isMacOS ? 68 : 20,
        isDesktop()
            ? 12
            : Platform.isIOS
            ? 74
            : 60,
        Platform.isWindows || Platform.isLinux ? 102 : 20,
        12,
      ),
      child: Row(
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.prefix.isNotEmpty || (widget.nested && !isDesktop()))
            SizedBox(
              width:
                  widget.nested && !isDesktop() && _sideWidth > 0
                      ? _sideWidth
                      : null,
              child: Row(
                key: _prefixKey,
                mainAxisSize: MainAxisSize.min,
                children: widget.prefix,
              ),
            ),
          if (widget.nested && !isDesktop())
            Expanded(child: Center(child: titleWidget))
          else
            Expanded(child: titleWidget),
          if (widget.suffix.isNotEmpty || (widget.nested && !isDesktop()))
            SizedBox(
              width:
                  widget.nested && !isDesktop() && _sideWidth > 0
                      ? _sideWidth
                      : null,
              child: Row(
                key: _suffixKey,
                mainAxisSize: MainAxisSize.min,
                children: widget.suffix,
              ),
            ),
        ],
      ),
    );
  }
}

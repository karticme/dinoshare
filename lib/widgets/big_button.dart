import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/util/utility_function.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as inset;
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../style/theme.dart';

enum DBigButtonVariant { primary, secondary, destructive, success, outline }

enum DBigButtonAlignment { start, center, end }

class DBigButtonStyle {
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? radius;
  final double? iconSize;
  final double? borderWidth;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Decoration? foregroundDecoration;
  final BorderRadiusGeometry? borderRadius;

  const DBigButtonStyle({
    this.height,
    this.width,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.radius,
    this.iconSize,
    this.borderWidth,
    this.borderColor,
    this.boxShadow,
    this.gradient,
    this.foregroundDecoration,
    this.borderRadius,
  });
}

class DBigButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final Widget icon;
  final DBigButtonVariant variant;
  final bool selected;
  final bool disabled;
  final DBigButtonStyle? style;

  const DBigButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.variant = DBigButtonVariant.primary,
    this.selected = false,
    this.disabled = false,
    this.style,
  });

  @override
  State<DBigButton> createState() => _DBigButtonState();
}

class _DBigButtonState extends State<DBigButton> {
  BorderRadiusGeometry borderRadiusMinus(
    BorderRadiusGeometry? br,
    double fallback, [
    double delta = 1,
  ]) {
    if (br == null) return BorderRadius.circular(fallback - delta);
    if (br is BorderRadius) {
      return BorderRadius.only(
        topLeft: Radius.circular(br.topLeft.x - delta),
        topRight: Radius.circular(br.topRight.x - delta),
        bottomLeft: Radius.circular(br.bottomLeft.x - delta),
        bottomRight: Radius.circular(br.bottomRight.x - delta),
      );
    }
    return BorderRadius.circular(fallback - delta);
  }

  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    // Sizing
    double height;
    EdgeInsetsGeometry padding;
    double fontSize;
    double radius;
    height =
        widget.variant == DBigButtonVariant.outline
            ? isDesktop()
                ? 62
                : 66
            : isDesktop()
            ? 60
            : 64;
    padding = const EdgeInsetsGeometry.fromLTRB(14, 8, 16, 0);
    fontSize = 20;
    radius = 16;

    final DBigButtonStyle style = widget.style ?? const DBigButtonStyle();
    height = style.height ?? height;
    padding = style.padding ?? padding;
    fontSize = style.fontSize ?? fontSize;
    radius = style.radius ?? radius;
    final double? styleIconSize = style.iconSize;
    final double? finalWidth = style.width;
    final BorderRadiusGeometry borderRadius =
        style.borderRadius ?? BorderRadius.circular(radius);

    final double defaultIconSize = 52;
    final double iconSize = styleIconSize ?? defaultIconSize;

    Color bg, fg, borderColor, iconColor;
    double borderWidth = 1;
    List<BoxShadow> shadow = [];
    Decoration? foregroundDecoration;
    switch (widget.variant) {
      case DBigButtonVariant.primary:
        bg = theme.colors.primary;
        fg = theme.colors.primaryForeground;
        borderColor = theme.colors.primary;
        iconColor = theme.colors.primaryForeground.withAlpha(70);
        shadow = [
          inset.BoxShadow(
            color: theme.colors.primary.withValues(alpha: 0.24),
            offset: const Offset(1, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          inset.BoxShadow(
            color: theme.colors.primary.withValues(alpha: 1),
            offset: Offset.zero,
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ];
        foregroundDecoration = inset.BoxDecoration(
          borderRadius: borderRadiusMinus(style.borderRadius, radius),
          boxShadow: [
            inset.BoxShadow(
              color: Color.fromRGBO(255, 255, 255, 0.16),
              offset: Offset(0, 1.5),
              blurRadius: 0,
              spreadRadius: 0,
              inset: true,
            ),
          ],
        );
        break;
      case DBigButtonVariant.secondary:
        bg = theme.colors.secondary;
        fg = theme.colors.secondaryForeground;
        borderColor = Color(0x00000000);
        iconColor = theme.colors.secondaryForeground.withAlpha(70);
        break;
      case DBigButtonVariant.destructive:
        bg = theme.colors.destructive;
        fg = theme.colors.destructiveForeground;
        borderColor = theme.colors.destructive;
        iconColor = theme.colors.destructiveForeground.withAlpha(70);
        shadow = [
          inset.BoxShadow(
            color: theme.colors.destructive.withValues(alpha: 0.24),
            offset: const Offset(1, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          inset.BoxShadow(
            color: theme.colors.destructive.withValues(alpha: 1),
            offset: Offset.zero,
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ];
        foregroundDecoration = inset.BoxDecoration(
          borderRadius: borderRadiusMinus(style.borderRadius, radius),
          boxShadow: [
            inset.BoxShadow(
              color: Color.fromRGBO(255, 255, 255, 0.2),
              offset: Offset(0, 1.5),
              blurRadius: 0,
              spreadRadius: 0,
              inset: true,
            ),
          ],
        );
        break;
      case DBigButtonVariant.success:
        bg = lCustom.success;
        fg = lCustom.successForeground;
        borderColor = lCustom.success;
        iconColor = lCustom.successForeground.withAlpha(70);
        shadow = [
          inset.BoxShadow(
            color: lCustom.success.withValues(alpha: 0.24),
            offset: const Offset(1, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          inset.BoxShadow(
            color: lCustom.success.withValues(alpha: 1),
            offset: Offset.zero,
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ];
        foregroundDecoration = inset.BoxDecoration(
          borderRadius: borderRadiusMinus(style.borderRadius, radius),
          boxShadow: [
            inset.BoxShadow(
              color: const Color.fromRGBO(255, 255, 255, 0.2),
              offset: const Offset(0, 1.5),
              blurRadius: 0,
              spreadRadius: 0,
              inset: true,
            ),
          ],
        );
        break;
      case DBigButtonVariant.outline:
        bg = _hovered ? theme.colors.secondary : theme.colors.background;
        fg = theme.colors.foreground;
        borderColor = theme.colors.border;
        iconColor = theme.colors.foreground.withAlpha(50);
        borderWidth = 1;
        shadow = [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.03),
            offset: const Offset(1, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ];
        foregroundDecoration = null;
        break;
    }

    if (widget.disabled) {
      bg = bg.withValues(alpha: 0.6);
      fg = fg.withValues(alpha: 0.6);
      borderColor = borderColor.withValues(alpha: 0.6);
      shadow =
          shadow
              .map((s) => s.copyWith(color: s.color.withValues(alpha: 0.6)))
              .toList();
    }

    final Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
      height: height,
      width: finalWidth,
      padding: padding,
      decoration: BoxDecoration(
        color: style.gradient != null ? null : bg,
        gradient: style.gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadow,
      ),
      foregroundDecoration: foregroundDecoration,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            DText(widget.label, size: DTextSize.h2, color: fg),
            Positioned(
              bottom: -16,
              right: 0,
              child: HugeIcon(
                icon: (widget.icon as HugeIcon).icon,
                color: iconColor,
                size: iconSize,
                strokeWidth: 1.25,
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:
            widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp:
            widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel:
            widget.disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: button,
      ),
    );
  }
}

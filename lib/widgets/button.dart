import 'package:flutter/widgets.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as inset;
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../style/typography.dart';
import '../style/theme.dart';

enum DButtonVariant { primary, secondary, destructive, success, ghost, outline }

enum DButtonSize { xs, sm, md, lg }

enum DButtonAlignment { start, center, end }

class DButtonStyle {
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? radius;
  final double? iconSize;
  final double? borderWidth;
  final Color? borderColor;
  final Color? textColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Decoration? foregroundDecoration;
  final BorderRadiusGeometry? borderRadius;

  const DButtonStyle({
    this.height,
    this.width,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.radius,
    this.iconSize,
    this.borderWidth,
    this.borderColor,
    this.textColor,
    this.boxShadow,
    this.gradient,
    this.foregroundDecoration,
    this.borderRadius,
  });
}

class DButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? prefix;
  final Widget? suffix;
  final DButtonVariant variant;
  final DButtonSize size;
  final DButtonAlignment alignment;
  final bool selected;
  final bool disabled;
  final DButtonStyle? style;
  final Color? textColor;

  const DButton({
    super.key,
    required this.child,
    this.prefix,
    this.suffix,
    this.onPressed,
    this.variant = DButtonVariant.primary,
    this.size = DButtonSize.md,
    this.alignment = DButtonAlignment.center,
    this.selected = false,
    this.disabled = false,
    this.style,
    this.textColor,
  });

  @override
  State<DButton> createState() => _DButtonState();
}

class _DButtonState extends State<DButton> {
  /// Returns a BorderRadius with all corners reduced by 1, or by [delta] if provided.
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
    // If not a BorderRadius, fallback to fallback - delta
    return BorderRadius.circular(fallback - delta);
  }

  bool _hovered = false;
  bool _pressed = false;

  AlignmentDirectional get _childAlignment {
    switch (widget.alignment) {
      case DButtonAlignment.start:
        return AlignmentDirectional.centerStart;
      case DButtonAlignment.end:
        return AlignmentDirectional.centerEnd;
      case DButtonAlignment.center:
        return AlignmentDirectional.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    // Sizing
    double height;
    EdgeInsetsGeometry padding;
    DTextSize labelSize;
    double radius;
    double spacing;
    switch (widget.size) {
      case DButtonSize.xs:
        height = widget.variant == DButtonVariant.outline ? 30 : 28;
        padding = const EdgeInsets.symmetric(horizontal: 10);
        labelSize = DTextSize.base;
        radius = 10;
        spacing = 4;
        break;
      case DButtonSize.sm:
        height = widget.variant == DButtonVariant.outline ? 34 : 32;
        padding = const EdgeInsets.symmetric(horizontal: 12);
        labelSize = DTextSize.base;
        radius = 10;
        spacing = 6;
        break;
      case DButtonSize.md:
        height = widget.variant == DButtonVariant.outline ? 42 : 40;
        padding = const EdgeInsets.symmetric(horizontal: 14);
        labelSize = DTextSize.h3;
        radius = 12;
        spacing = 6;
        break;
      case DButtonSize.lg:
        height = widget.variant == DButtonVariant.outline ? 46 : 44;
        padding = const EdgeInsets.symmetric(horizontal: 16);
        labelSize = DTextSize.h2;
        radius = 14;
        spacing = 6;
        break;
    }

    final bool isIconOnly =
        widget.prefix == null &&
        widget.suffix == null &&
        (widget.child is HugeIcon ||
            widget.child is Icon ||
            widget.child is Image ||
            widget.child.runtimeType.toString() == 'FIcon');
    final double? width = isIconOnly ? height : null;
    if (isIconOnly) {
      padding = EdgeInsets.zero;
    }

    final DButtonStyle style = widget.style ?? const DButtonStyle();
    height = style.height ?? height;
    padding = style.padding ?? padding;
    radius = style.radius ?? radius;
    final double? styleIconSize = style.iconSize;
    final double? finalWidth = style.width ?? width;
    final BorderRadiusGeometry borderRadius =
        style.borderRadius ?? BorderRadius.circular(radius);

    final Color? effectiveTextColor = widget.textColor ?? style.textColor;
    final double defaultIconSize;
    switch (widget.size) {
      case DButtonSize.xs:
        defaultIconSize = 16;
        break;
      case DButtonSize.sm:
        defaultIconSize = 18;
        break;
      case DButtonSize.md:
        defaultIconSize = 20;
        break;
      case DButtonSize.lg:
        defaultIconSize = 22;
        break;
    }
    final double iconSize = styleIconSize ?? defaultIconSize;

    // Colors, border, and shadow logic
    Color bg, fg, borderColor;
    double borderWidth = 1;
    List<BoxShadow> shadow = [];
    Decoration? foregroundDecoration;
    switch (widget.variant) {
      case DButtonVariant.primary:
        bg = theme.colors.primary;
        fg = theme.colors.primaryForeground;
        borderColor = theme.colors.primary;
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
      case DButtonVariant.secondary:
        bg = theme.colors.secondary;
        fg = theme.colors.secondaryForeground;
        borderColor = Color(0x00000000);
        break;
      case DButtonVariant.destructive:
        bg = theme.colors.destructive;
        fg = theme.colors.destructiveForeground;
        borderColor = theme.colors.destructive;
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
      case DButtonVariant.success:
        bg = lCustom.success;
        fg = lCustom.successForeground;
        borderColor = lCustom.success;
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
      case DButtonVariant.ghost:
        bg = theme.colors.secondary.withValues(alpha: _hovered ? 1.0 : 0.0);
        {}
        fg = theme.colors.foreground;
        borderColor = Color(0x00000000);
        borderWidth = 0;
        break;
      case DButtonVariant.outline:
        bg = _hovered ? theme.colors.secondary : theme.colors.background;
        {}
        fg = theme.colors.foreground;
        borderColor = theme.colors.border;
        borderWidth = 1;
        shadow = [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.05),
            offset: const Offset(1, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ];
        foregroundDecoration = null;
        break;
    }

    borderColor = style.borderColor ?? borderColor;
    borderWidth = style.borderWidth ?? borderWidth;
    shadow = style.boxShadow ?? shadow;
    if (widget.disabled) {
      bg = bg.withValues(alpha: 0.6);
      fg = fg.withValues(alpha: 0.6);
      borderColor = borderColor.withValues(alpha: 0.6);
      shadow =
          shadow
              .map((s) => s.copyWith(color: s.color.withValues(alpha: 0.6)))
              .toList();
    }

    Widget wrapIcon(Widget widget) {
      if (widget is HugeIcon) {
        final iconColor = widget.color ?? effectiveTextColor ?? fg;
        return HugeIcon(
          icon: widget.icon,
          color: iconColor,
          secondaryColor: widget.secondaryColor,
          size: widget.size ?? iconSize,
          strokeWidth: widget.strokeWidth,
        );
      }
      return IconTheme(
        data: IconThemeData(size: iconSize, color: effectiveTextColor ?? fg),
        child: widget,
      );
    }

    final List<Widget> content = [];
    if (widget.prefix != null) {
      content.add(wrapIcon(widget.prefix!));
    }
    Widget labelWidget(Widget child) {
      if (child is DText) {
        return DText(
          child.text,
          size: labelSize,
          color: effectiveTextColor ?? fg,
          weight: child.weight ?? style.fontWeight ?? FontWeight.w500,
          textAlign: child.textAlign,
          maxLines: child.maxLines,
          overflow: child.overflow,
          softWrap: child.softWrap,
        );
      }
      if (child is Text) {
        return DText(
          child.data ?? '',
          size: labelSize,
          color: effectiveTextColor ?? fg,
          weight:
              child.style?.fontWeight ?? style.fontWeight ?? FontWeight.w500,
          textAlign: child.textAlign,
          maxLines: child.maxLines,
          overflow: child.overflow,
          softWrap: child.softWrap ?? true,
        );
      }
      return child;
    }

    content.add(
      widget.child is HugeIcon ||
              widget.child is Icon ||
              widget.child.runtimeType.toString() == 'FIcon' ||
              widget.child is Image
          ? wrapIcon(widget.child)
          : labelWidget(widget.child),
    );
    if (widget.suffix != null) {
      content.add(wrapIcon(widget.suffix!));
    }

    final Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
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
      child: Align(
        alignment: _childAlignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: spacing,
          children: content,
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

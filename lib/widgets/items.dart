import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../style/typography.dart';

class DItemList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;
  final Clip clipBehavior;

  const DItemList({
    super.key,
    required this.children,
    this.spacing = 2,
    this.padding,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor ?? Color.fromARGB(0, 255, 255, 255),
      border: border,
      borderRadius: borderRadius ?? BorderRadius.circular(0),
    );

    final BorderRadiusGeometry itemBorderRadius =
        borderRadius ?? BorderRadius.circular(0);
    final List<Widget> itemWidgets = [
      for (var i = 0; i < children.length; i++)
        ClipRRect(
          borderRadius:
              children.length == 1
                  ? itemBorderRadius
                  : i == 0
                  ? BorderRadius.only(
                    topLeft:
                        itemBorderRadius.resolve(TextDirection.ltr).topLeft,
                    topRight:
                        itemBorderRadius.resolve(TextDirection.ltr).topRight,
                  )
                  : i == children.length - 1
                  ? BorderRadius.only(
                    bottomLeft:
                        itemBorderRadius.resolve(TextDirection.ltr).bottomLeft,
                    bottomRight:
                        itemBorderRadius.resolve(TextDirection.ltr).bottomRight,
                  )
                  : BorderRadius.zero,
          child: children[i],
        ),
    ];

    return DecoratedBox(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(0),
        clipBehavior: clipBehavior,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: spacing,
            children: itemWidgets,
          ),
        ),
      ),
    );
  }
}

/// A single row item inside [DItemList].
///
/// Supports optional [prefix], [description], [suffix], [borderRadius], and [onPressed].
class DItem extends StatefulWidget {
  final Widget? prefix;
  final Widget title;
  final Widget? description;
  final Widget? suffix;
  final VoidCallback? onPressed;
  final bool disabled;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? hoverColor;
  final Color? borderColor;
  final BorderRadiusGeometry? borderRadius;
  final double spacing;
  final double minHeight;
  final bool compact;

  const DItem({
    super.key,
    this.prefix,
    required this.title,
    this.description,
    this.suffix,
    this.onPressed,
    this.disabled = false,
    this.padding,
    this.backgroundColor,
    this.hoverColor,
    this.borderColor,
    this.borderRadius,
    this.spacing = 12,
    this.minHeight = 48,
    this.compact = false,
  });

  @override
  State<DItem> createState() => _DItemState();
}

class _DItemState extends State<DItem> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final Color defaultBackground = theme.colors.background;
    final Color effectiveBackground =
        widget.backgroundColor ?? defaultBackground;
    final bool interactive = widget.onPressed != null && !widget.disabled;
    final Color background =
        _pressed
            ? effectiveBackground.withValues(alpha: 1)
            : (_hovered && interactive
                ? (widget.hoverColor ??
                    effectiveBackground.withValues(alpha: 0.6))
                : effectiveBackground);

    final Color titleColor = theme.colors.foreground;
    final Color descriptionColor = theme.colors.mutedForeground;
    final Color borderColor = widget.borderColor ?? const Color(0x00000000);
    final double spacing = widget.spacing;

    Widget wrapIcon(Widget icon) {
      if (icon is HugeIcon) {
        return HugeIcon(
          icon: icon.icon,
          color: icon.color ?? titleColor,
          secondaryColor: icon.secondaryColor,
          size: icon.size != 24.0 ? icon.size : 20,
          strokeWidth: icon.strokeWidth,
        );
      }
      return IconTheme(
        data: IconThemeData(size: 20, color: titleColor),
        child: icon,
      );
    }

    final List<Widget> rowChildren = [];
    if (widget.prefix != null) {
      rowChildren.add(wrapIcon(widget.prefix!));
    }

    Widget titleWidget = widget.title;
    if (titleWidget is Text) {
      titleWidget = DText(
        titleWidget.data ?? '',
        size: DTextSize.base,
        color: titleColor,
        weight: titleWidget.style?.fontWeight ?? FontWeight.w500,
        textAlign: titleWidget.textAlign,
        maxLines: titleWidget.maxLines,
        overflow: titleWidget.overflow,
        softWrap: titleWidget.softWrap ?? true,
      );
    }

    Widget? descriptionWidget = widget.description;
    if (descriptionWidget is Text) {
      descriptionWidget = DText(
        descriptionWidget.data ?? '',
        size: DTextSize.sm,
        color: descriptionColor,
        weight: descriptionWidget.style?.fontWeight ?? FontWeight.w400,
        textAlign: descriptionWidget.textAlign,
        maxLines: descriptionWidget.maxLines,
        overflow: descriptionWidget.overflow,
        softWrap: descriptionWidget.softWrap ?? true,
      );
    }

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleWidget, if (descriptionWidget != null) descriptionWidget],
    );
    rowChildren.add(widget.compact ? content : Expanded(child: content));

    if (widget.suffix != null) {
      rowChildren.add(wrapIcon(widget.suffix!));
    }

    return MouseRegion(
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      child: Opacity(
        opacity: widget.disabled ? 0.6 : 1,
        child: GestureDetector(
          onTapDown:
              interactive ? (_) => setState(() => _pressed = true) : null,
          onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              interactive ? () => setState(() => _pressed = false) : null,
          onTap: interactive ? widget.onPressed : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: theme.colors.foreground.withAlpha(2),
                  offset: Offset(1, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: spacing,
              children: rowChildren,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:dinoshare/util/utility_function.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

enum DTextSize { title, h1, h2, h3, base, sm, xs }

class DText extends StatelessWidget {
  final String? text;
  final InlineSpan? textSpan;
  final DTextSize size;
  final Color? color;
  final FontWeight? weight;
  final List<FontFeature>? fontFeatures;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const DText(
    this.text, {
    super.key,
    this.size = DTextSize.base,
    this.color,
    this.weight,
    this.fontFeatures,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  }) : textSpan = null;

  const DText.rich(
    this.textSpan, {
    super.key,
    this.size = DTextSize.base,
    this.color,
    this.weight,
    this.fontFeatures,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  }) : text = null;

  @override
  Widget build(BuildContext context) {
    final spec = size._spec;
    final effectiveWeight = weight ?? spec.weight;
    final foreground = color ?? context.theme.colors.foreground;
    final baseStyle = context.theme.typography.md.copyWith(
      fontSize: spec.fontSize,
      fontWeight: effectiveWeight,
      letterSpacing: spec.letterSpacing,
      height: spec.height,
      color: foreground,
      fontFeatures: fontFeatures,
    );
    final textStyle = GoogleFonts.inter(
      textStyle: baseStyle,
      fontWeight: effectiveWeight,
    );
    final strutStyle = StrutStyle(
      fontFamily: textStyle.fontFamily,
      fontSize: spec.fontSize,
      fontWeight: effectiveWeight,
      height: spec.height,
      forceStrutHeight: true,
    );

    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        style: textStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        strutStyle: strutStyle,
      );
    }

    return Text(
      text!,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      strutStyle: strutStyle,
    );
  }
}

class _DTextSpec {
  final double fontSize;
  final double height;
  final double letterSpacing;
  final FontWeight weight;

  const _DTextSpec({
    required this.fontSize,
    required this.height,
    required this.letterSpacing,
    required this.weight,
  });
}

extension on DTextSize {
  _DTextSpec get _spec {
    switch (this) {
      case DTextSize.title:
        return _DTextSpec(
          fontSize: isDesktop() ? 28 : 30,
          height: 1.5,
          letterSpacing: isDesktop() ? -0.59 : -0.64,
          weight: FontWeight.bold,
        );
      case DTextSize.h1:
        return _DTextSpec(
          fontSize: isDesktop() ? 24 : 26,
          height: 1.4,
          letterSpacing: isDesktop() ? -0.47 : -0.53,
          weight: FontWeight.w600,
        );
      case DTextSize.h2:
        return _DTextSpec(
          fontSize: isDesktop() ? 20 : 22,
          height: 1.35,
          letterSpacing: isDesktop() ? -0.33 : -0.4,
          weight: FontWeight.w600,
        );
      case DTextSize.h3:
        return _DTextSpec(
          fontSize: isDesktop() ? 16 : 18,
          height: 1.3,
          letterSpacing: isDesktop() ? -0.18 : -0.26,
          weight: FontWeight.w600,
        );
      case DTextSize.base:
        return _DTextSpec(
          fontSize: isDesktop() ? 14 : 16,
          height: 1.3,
          letterSpacing: -0.18,
          weight: FontWeight.w400,
        );
      case DTextSize.sm:
        return _DTextSpec(
          fontSize: isDesktop() ? 12 : 14,
          height: 1.3,
          letterSpacing: -0.09,
          weight: FontWeight.w400,
        );
      case DTextSize.xs:
        return _DTextSpec(
          fontSize: isDesktop() ? 10 : 12,
          height: 1.3,
          letterSpacing: isDesktop() ? 0.1 : 0.01,
          weight: FontWeight.w400,
        );
    }
  }
}

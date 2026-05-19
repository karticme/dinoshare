
import 'package:dinoshare/style/typography.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:dinoshare/widgets/button.dart';

import '../style/theme.dart';

enum DProgressbarVariant { primary, destructive, success }

class DProgressbar extends StatefulWidget {
  final double value;
  final String label;
  final DProgressbarVariant variant;
  final bool runningSpark;

  const DProgressbar({
    super.key,
    required this.value,
    this.label = '',
    this.variant = DProgressbarVariant.primary,
    this.runningSpark = true,
  });

  @override
  State<DProgressbar> createState() => _DProgressbarState();
}

class _DProgressbarState extends State<DProgressbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sparkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _sparkAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _buildSparkGradient(
    double animValue,
    Color backColor,
    Color foreColor,
  ) {
    final double spark = -0.5 + animValue * 1.5;

    final Color p = backColor.withValues(alpha: 0.20);
    final Color pf = foreColor;

    double s0 = (spark - 0.25).clamp(0.0, 1.0);
    double s1 = (spark - 0.05).clamp(0.0, 1.0);
    double s2 = (spark + 0.10).clamp(0.0, 1.0);
    double s3 = (spark + 0.30).clamp(0.0, 1.0);

    final stops = [s0, s1, s2, s3];
    final colors = [p, p, pf, p];

    final List<double> cleanStops = [];
    final List<Color> cleanColors = [];
    for (int i = 0; i < stops.length; i++) {
      if (cleanStops.isEmpty || stops[i] != cleanStops.last) {
        cleanStops.add(stops[i]);
        cleanColors.add(colors[i]);
      }
    }

    while (cleanStops.length < 2) {
      cleanStops.add(1.0);
      cleanColors.add(p);
    }

    return LinearGradient(
      begin: Alignment(-2.0, -1.0),
      end: Alignment(2.0, 1.0),
      stops: cleanStops,
      colors: cleanColors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );
    final double clampedValue = widget.value.clamp(0.0, 100.0);

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double progressWidth =
              constraints.maxWidth * clampedValue / 100;

          return AnimatedBuilder(
            animation: _sparkAnim,
            builder: (context, _) {
              final gradient = _buildSparkGradient(
                _sparkAnim.value,
                widget.variant == DProgressbarVariant.destructive
                    ? theme.colors.destructive
                    : widget.variant == DProgressbarVariant.success
                    ? lCustom.success
                    : theme.colors.primary,
                widget.variant == DProgressbarVariant.destructive
                    ? theme.colors.destructiveForeground.withValues(alpha: 0.5)
                    : widget.variant == DProgressbarVariant.success
                    ? lCustom.successForeground.withValues(alpha: 0.5)
                    : theme.colors.primaryForeground.withValues(alpha: 0.4),
              );

              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: theme.colors.border,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DText(
                          widget.label,
                          color: theme.colors.mutedForeground,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        width: progressWidth,
                        height: 30,
                        child: DButton(
                          size: DButtonSize.xs,
                          variant:
                              widget.variant == DProgressbarVariant.success
                                  ? DButtonVariant.success
                                  : widget.variant ==
                                      DProgressbarVariant.destructive
                                  ? DButtonVariant.destructive
                                  : DButtonVariant.primary,
                          alignment: DButtonAlignment.start,
                          style: DButtonStyle(
                            radius: 16,
                            fontWeight: FontWeight.w400,
                            gradient: widget.runningSpark ? gradient : null,
                          ),
                          child: DText(
                            widget.label,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

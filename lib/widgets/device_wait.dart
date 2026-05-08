import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:dinoshare/widgets/button.dart';

import '../style/theme.dart';

enum DeviceWaitVariant { normal, primary, destructive, success }

class DeviceWait extends StatefulWidget {
  final Widget child;
  final DeviceWaitVariant variant;

  const DeviceWait({
    super.key,
    this.child = const SizedBox.shrink(),
    this.variant = DeviceWaitVariant.normal,
  });

  @override
  State<DeviceWait> createState() => _DeviceWaitState();
}

class _DeviceWaitState extends State<DeviceWait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _tween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _tween = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.duration = const Duration(milliseconds: 1500);
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.duration = const Duration(milliseconds: 2000);
        _controller.forward();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    // Expanded and squeezed sizes for each ring
    const expanded = [372.0, 308.0, 244.0, 180.0, 132.0];
    const squeezed = [176.0, 144.0, 120.0, 100.0, 80.0];
    const expandedBorder = [1.0, 2.0, 3.0, 0.0, 0.0];
    const squeezedBorder = [1.0, 1.0, 1.0, 0.0, 0.0];
    const expandedAlpha = [20, 30, 40, 50, 60];
    const squeezedAlpha = [20, 30, 40, 50, 60];

    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _tween,
        builder: (context, child) {
          final t = _tween.value;
          List<Widget> rings = [];
          for (int i = 0; i < 5; i++) {
            final double size = expanded[i] * t + squeezed[i] * (1 - t);
            final double borderWidth =
                expandedBorder[i] * t + squeezedBorder[i] * (1 - t);
            final int alpha =
                (expandedAlpha[i] * t + squeezedAlpha[i] * (1 - t)).round();
            final bool isBorder = borderWidth > 0;
            rings.add(
              OverflowBox(
                minWidth: 0,
                maxWidth: double.infinity,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border:
                        isBorder
                            ? Border.all(
                              color:
                                  widget.variant ==
                                          DeviceWaitVariant.destructive
                                      ? theme.colors.destructive.withAlpha(
                                        alpha,
                                      )
                                      : widget.variant ==
                                          DeviceWaitVariant.success
                                      ? lCustom.success.withAlpha(alpha)
                                      : widget.variant ==
                                          DeviceWaitVariant.primary
                                      ? theme.colors.primary.withAlpha(alpha)
                                      : theme.colors.foreground.withAlpha(
                                        alpha,
                                      ),
                              width: borderWidth,
                            )
                            : null,
                    color:
                        !isBorder
                            ? widget.variant == DeviceWaitVariant.destructive
                                ? theme.colors.destructive.withAlpha(alpha)
                                : widget.variant == DeviceWaitVariant.success
                                ? lCustom.success.withAlpha(alpha)
                                : widget.variant == DeviceWaitVariant.primary
                                ? theme.colors.primary.withAlpha(alpha)
                                : theme.colors.foreground.withAlpha(alpha)
                            : null,
                  ),
                ),
              ),
            );
          }
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              ...rings,
              DButton(
                size: DButtonSize.lg,
                variant:
                    widget.variant == DeviceWaitVariant.destructive
                        ? DButtonVariant.destructive
                        : widget.variant == DeviceWaitVariant.success
                        ? DButtonVariant.success
                        : widget.variant == DeviceWaitVariant.primary
                        ? DButtonVariant.primary
                        : DButtonVariant.outline,
                style: DButtonStyle(
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: widget.child,
              ),
            ],
          );
        },
      ),
    );
  }
}

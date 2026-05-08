import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../style/theme.dart';

enum DSwitchVariant { primary, success }

class DSwitch extends StatefulWidget {
  final bool on;
  final VoidCallback? onPressed;
  final DSwitchVariant variant;
  final bool disabled;
  final double width;
  final double height;
  final Duration duration;

  const DSwitch({
    super.key,
    required this.on,
    required this.onPressed,
    this.variant = DSwitchVariant.primary,
    this.disabled = false,
    this.width = 40,
    this.height = 20,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<DSwitch> createState() => _DSwitchState();
}

class _DSwitchState extends State<DSwitch> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );
    final bool isOn = widget.on;
    final bool isDisabled = widget.disabled;
    final Color activeColor =
        widget.variant == DSwitchVariant.success
            ? lCustom.success
            : theme.colors.primary;
    final double trackHeight = widget.height;
    final double trackWidth = widget.width;
    final double knobSize = trackHeight - 4;
    final double knobPadding = 2;
    final bool isPressed = _pressed && !isDisabled;
    final double opacity = isDisabled ? 0.5 : 1.0;

    final Color trackColor =
        isOn
            ? activeColor.withValues(alpha: isDisabled ? 0.22 : 1)
            : theme.colors.secondary;
    final Color knobColor =
        widget.variant == DSwitchVariant.success
            ? lCustom.successForeground
            : theme.colors.primaryForeground;
    final Alignment knobAlignment =
        isOn ? Alignment.centerRight : Alignment.centerLeft;
    final Color trackFill = trackColor;

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp:
            isDisabled
                ? null
                : (_) {
                  widget.onPressed?.call();
                  Future.delayed(widget.duration, () {
                    if (!mounted) return;
                    setState(() => _pressed = false);
                  });
                },
        onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
        onTap: null,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          toggled: isOn,
          enabled: !isDisabled,
          child: AnimatedOpacity(
            duration: widget.duration,
            opacity: opacity,
            child: AnimatedContainer(
              duration: widget.duration,
              width: trackWidth,
              height: trackHeight,
              padding: EdgeInsets.all(knobPadding),
              decoration: BoxDecoration(
                color: trackFill,
                borderRadius: BorderRadius.circular(trackHeight / 2),
              ),
              child: AnimatedAlign(
                duration: widget.duration,
                alignment: knobAlignment,
                curve: Curves.easeInOut,
                child: AnimatedContainer(
                  duration: widget.duration,
                  curve: Curves.easeInOut,
                  width:
                      isPressed
                          ? (trackWidth - knobSize) + 2
                          : trackWidth - knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    color: knobColor,
                    borderRadius: BorderRadius.circular(knobSize / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.04),
                        offset: const Offset(1, 2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

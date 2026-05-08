import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class StackedDialogController extends ChangeNotifier {
  final List<Widget> _dialogs = [];

  List<Widget> get dialogs => List.unmodifiable(_dialogs);

  bool get isEmpty => _dialogs.isEmpty;

  bool get isNotEmpty => _dialogs.isNotEmpty;

  int get length => _dialogs.length;

  void setDialogs(List<Widget> dialogs) {
    _dialogs
      ..clear()
      ..addAll(dialogs);
    notifyListeners();
  }

  void addDialog(Widget dialog) {
    _dialogs.add(dialog);
    notifyListeners();
  }

  void removeDialog(Widget dialog) {
    final removed = _dialogs.remove(dialog);
    if (removed) {
      notifyListeners();
    }
  }

  void removeAt(int index) {
    if (index < 0 || index >= _dialogs.length) return;
    _dialogs.removeAt(index);
    notifyListeners();
  }

  void removeTop() {
    if (_dialogs.isEmpty) return;
    _dialogs.removeLast();
    notifyListeners();
  }

  void clear() {
    if (_dialogs.isEmpty) return;
    _dialogs.clear();
    notifyListeners();
  }
}

class StackedDialog extends StatefulWidget {
  final List<Widget> children;
  final StackedDialogController? controller;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final double firstGap;
  final double secondGap;
  final double scaleStep;
  final double maxWidth;
  final double blurSigma;
  final Color? barrierColor;
  final Duration duration;

  const StackedDialog({
    super.key,
    required this.children,
    this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.alignment = Alignment.center,
    this.firstGap = 7,
    this.secondGap = 6,
    this.scaleStep = 0.05,
    this.maxWidth = 400,
    this.blurSigma = 4,
    this.barrierColor,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  State<StackedDialog> createState() => _StackedDialogState();
}

class _StackedDialogState extends State<StackedDialog> {
  late StackedDialogController _controller;
  late final bool _ownsController;
  Size? _frontSize;
  Widget? _frontDialog;
  int _dialogCount = 0;
  double _frontEntryOffset = 0;
  double _frontEntryScale = 1;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? StackedDialogController();
    _controller.addListener(_onControllerChanged);
    if (_controller.isEmpty && widget.children.isNotEmpty) {
      _controller.setDialogs(widget.children);
    }
    _syncFrontState(animatePromotion: false);
  }

  @override
  void didUpdateWidget(covariant StackedDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller &&
        widget.controller != null) {
      _controller.removeListener(_onControllerChanged);
      _controller = widget.controller!;
      _controller.addListener(_onControllerChanged);
    }
    if (widget.controller == null && oldWidget.children != widget.children) {
      _controller.setDialogs(widget.children);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() => _syncFrontState(animatePromotion: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final dialogs = _controller.dialogs;
    if (dialogs.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleBackLayers = math.min(dialogs.length - 1, 2);
    final backOffset = _offsetForDepth(visibleBackLayers);
    final barrierColor =
        widget.barrierColor ?? theme.colors.foreground.withValues(alpha: 0.18);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: ColoredBox(
          color: barrierColor,
          child: Padding(
            padding: widget.padding,
            child: Align(
              alignment: widget.alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Padding(
                  padding: EdgeInsets.only(bottom: backOffset),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      for (var depth = visibleBackLayers; depth >= 1; depth--)
                        _StackedDialogDummyLayer(
                          size: _frontSize,
                          offset: _offsetForDepth(depth),
                          scale: _scaleForDepth(depth),
                          duration: widget.duration,
                        ),
                      _StackedDialogFrontLayer(
                        key: ObjectKey(dialogs.last),
                        duration: widget.duration,
                        initialOffset: _frontEntryOffset,
                        initialScale: _frontEntryScale,
                        onSizeChanged: _onFrontSizeChanged,
                        child: dialogs.last,
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

  double _offsetForDepth(int depth) {
    if (depth <= 0) return 0;
    if (depth == 1) return widget.firstGap;
    return widget.firstGap + widget.secondGap;
  }

  double _scaleForDepth(int depth) {
    return math.max(0, 1 - depth * widget.scaleStep);
  }

  void _onFrontSizeChanged(Size size) {
    if (!mounted || _frontSize == size) return;
    setState(() => _frontSize = size);
  }

  void _syncFrontState({required bool animatePromotion}) {
    final dialogs = _controller.dialogs;
    final nextFront = dialogs.isEmpty ? null : dialogs.last;
    final isPromotingFront =
        animatePromotion &&
        _frontDialog != null &&
        nextFront != null &&
        _frontDialog != nextFront &&
        dialogs.length < _dialogCount;

    _frontEntryOffset = isPromotingFront ? _offsetForDepth(1) : 0;
    _frontEntryScale = isPromotingFront ? _scaleForDepth(1) : 1;
    _frontDialog = nextFront;
    _dialogCount = dialogs.length;
  }
}

class _StackedDialogFrontLayer extends StatelessWidget {
  final Duration duration;
  final double initialOffset;
  final double initialScale;
  final ValueChanged<Size> onSizeChanged;
  final Widget child;

  const _StackedDialogFrontLayer({
    super.key,
    required this.duration,
    required this.initialOffset,
    required this.initialScale,
    required this.onSizeChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: TweenAnimationBuilder<double>(
        duration: duration,
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: initialOffset, end: 0),
        child: TweenAnimationBuilder<double>(
          duration: duration,
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: initialScale, end: 1),
          child: _MeasureSize(onChanged: onSizeChanged, child: child),
          builder:
              (context, scale, child) => Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
        ),
        builder:
            (context, offset, child) =>
                Transform.translate(offset: Offset(0, offset), child: child),
      ),
    );
  }
}

class _StackedDialogDummyLayer extends StatelessWidget {
  final Size? size;
  final double offset;
  final double scale;
  final Duration duration;

  const _StackedDialogDummyLayer({
    required this.size,
    required this.offset,
    required this.scale,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final layerSize = size;

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: duration,
        curve: Curves.easeOutCubic,
        opacity: layerSize == null ? 0 : 1,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, offset, 0),
          transformAlignment: Alignment.bottomCenter,
          child: AnimatedScale(
            duration: duration,
            curve: Curves.easeOutCubic,
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: layerSize?.width,
              height: layerSize?.height,
              child: DecoratedBox(
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChanged;

  const _MeasureSize({required this.onChanged, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  ValueChanged<Size> onChanged;
  Size? _oldSize;

  _RenderMeasureSize(this.onChanged);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = size;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(newSize));
  }
}

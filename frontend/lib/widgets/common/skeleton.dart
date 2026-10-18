import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../styles/widgets/common/skeleton_styles.dart';

/// Drives one shared shimmer for every [SkeletonBox] and [SkeletonLine]
/// below it. When the phone asks to reduce motion, the shimmer stops and
/// the shapes are drawn in their solid base color.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({super.key, required this.child});

  final Widget child;

  static Animation<double>? _animationOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SkeletonAnimation>()
        ?.animation;
  }

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SkeletonStyles.shimmerDuration,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SkeletonAnimation(
      animation: _reduceMotion ? null : _controller,
      child: widget.child,
    );
  }
}

class _SkeletonAnimation extends InheritedWidget {
  const _SkeletonAnimation({required this.animation, required super.child});

  final Animation<double>? animation;

  @override
  bool updateShouldNotify(_SkeletonAnimation oldWidget) {
    return animation != oldWidget.animation;
  }
}

/// A placeholder block with the same size and corners as the real content.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius = SkeletonStyles.lineRadius,
    this.isCircle = false,
  });

  final double? width;
  final double? height;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadius borderRadius;
  final bool isCircle;

  BoxDecoration _decoration(double? shimmerValue) {
    return BoxDecoration(
      color: shimmerValue == null ? baseColor : null,
      gradient: shimmerValue == null ? null : _shimmerGradient(shimmerValue),
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : borderRadius,
    );
  }

  LinearGradient _shimmerGradient(double value) {
    const double band = SkeletonStyles.shimmerBandHalfWidth;

    // The band center travels from just left of the shape to just right
    // of it, so each sweep starts and ends on the plain base color.
    final double center = -band + (1 + 2 * band) * value;

    return LinearGradient(
      colors: <Color>[baseColor, highlightColor, baseColor],
      stops: <double>[
        math.max(0, center - band),
        center.clamp(0.0, 1.0),
        math.min(1, center + band),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double>? animation = SkeletonScope._animationOf(context);

    if (animation == null) {
      return SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(decoration: _decoration(null)),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return DecoratedBox(decoration: _decoration(animation.value));
        },
      ),
    );
  }
}

/// A placeholder for one line of text. Its height comes from an invisible
/// line in the real [style], so the layout does not move when the real
/// text replaces it, including with larger system font sizes.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    required this.style,
    required this.widthFactor,
    required this.baseColor,
    required this.highlightColor,
  });

  final TextStyle style;

  /// Bar width as a fraction of the available width.
  final double widthFactor;

  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final double fontSize = style.fontSize ?? SkeletonStyles.fallbackFontSize;

    return ExcludeSemantics(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Stack(
          children: <Widget>[
            Text(
              ' ',
              maxLines: 1,
              style: style.copyWith(color: Colors.transparent),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: fontSize * SkeletonStyles.lineInsetFactor,
                ),
                child: SkeletonBox(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

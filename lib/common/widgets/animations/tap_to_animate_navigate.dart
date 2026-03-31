import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// Shows a static image and, when triggered (tap or external trigger),
/// replaces it with an animation (Lottie or GIF). After the animation
/// completes the widget resets to the static image and then navigates via
/// `onNavigate` or `routeName`.
class TapToAnimateNavigate extends StatefulWidget {
  final String imageAsset;
  final String animationAsset;
  final bool isLottie;
  final Duration? gifDuration;
  final VoidCallback? onNavigate;
  final String? routeName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ValueNotifier<int>? externalTrigger;
  /// Duration used by the internal [AnimatedSwitcher] fade transition.
  /// Defaults to 300ms to preserve previous behaviour.
  final Duration fadeDuration;
  /// Scale applied to the animation (gif or lottie). 1.0 means same size
  /// as the static image. Values > 1.0 make the animation larger.
  final double animationScale;

  const TapToAnimateNavigate({
	Key? key,
	required this.imageAsset,
	required this.animationAsset,
	this.isLottie = false,
	this.gifDuration,
	this.onNavigate,
	this.routeName,
	this.width,
	this.height,
	this.fit = BoxFit.cover,
	this.externalTrigger,
	this.fadeDuration = const Duration(milliseconds: 300),
	this.animationScale = 1.0,
  }) : super(key: key);

  @override
  State<TapToAnimateNavigate> createState() => _TapToAnimateNavigateState();
}

class _TapToAnimateNavigateState extends State<TapToAnimateNavigate>
	with SingleTickerProviderStateMixin {
  bool _playing = false;
  AnimationController? _lottieController;
  VoidCallback? _externalListener;
  Key? _animationKey;

  @override
  void initState() {
	super.initState();
	if (widget.externalTrigger != null) {
	  _externalListener = () {
		if (mounted) _play();
	  };
	  widget.externalTrigger!.addListener(_externalListener!);
	}
  }

  @override
  void dispose() {
	if (_externalListener != null && widget.externalTrigger != null) {
	  widget.externalTrigger!.removeListener(_externalListener!);
	}
	_lottieController?.dispose();
	super.dispose();
  }

  Future<void> _completeAndNavigate() async {
	if (!mounted) return;
	// Reset to static image so returning to this screen shows static state
	setState(() {
	  _playing = false;
	  _animationKey = null;
	});
	// allow a microtask for UI to update
	await Future.microtask(() {});
	_navigateAfterAnimation();
  }

  void _navigateAfterAnimation() {
	if (widget.onNavigate == null && widget.routeName == null) return;
	if (widget.onNavigate != null) {
	  widget.onNavigate!.call();
	} else if (widget.routeName != null) {
	  Get.toNamed(widget.routeName!);
	}
  }

  Future<void> _play() async {
	if (_playing) return;
	// Give the animation widget a fresh key so Image/Lottie re-creates and
	// always starts from its first frame.
	setState(() {
	  _animationKey = UniqueKey();
	  _playing = true;
	});

	if (widget.isLottie) {
	  if (_lottieController == null) {
		_lottieController = AnimationController(vsync: this);
	  }
	  _lottieController!.reset();
	  _lottieController!.forward();
	} else {
	  final duration = widget.gifDuration ?? const Duration(seconds: 3);
	  await Future.delayed(duration);
	  await _completeAndNavigate();
	}
  }

  @override
  Widget build(BuildContext context) {
	// Use LayoutBuilder to determine available size; fallback to a sensible
	// default equal to the product image size used elsewhere in the app so
	// animation and image match visually.
	return GestureDetector(
	  onTap: _play,
	  child: LayoutBuilder(builder: (context, constraints) {
		final double defaultSize = BSizes.productImageSize * 1.6;
		final double w = widget.width ??
			(constraints.hasBoundedWidth ? constraints.maxWidth : defaultSize);
		final double h = widget.height ??
			(constraints.hasBoundedHeight ? constraints.maxHeight : defaultSize);

		final scale = widget.animationScale;
		final outerW = math.max(w, w * scale);
		final outerH = math.max(h, h * scale);

		return SizedBox(
		  // Make the outer container large enough to contain the scaled animation
		  width: outerW,
		  height: outerH,
		  child: AnimatedSwitcher(
					duration: widget.fadeDuration,
			switchInCurve: Curves.easeIn,
			switchOutCurve: Curves.easeOut,
			transitionBuilder: (child, animation) => FadeTransition(
			  opacity: animation,
			  child: child,
			),
			// Use different keys so AnimatedSwitcher can tell the widgets apart
						child: Center(
						  child: _playing
							? KeyedSubtree(
								key: _animationKey ?? const ValueKey('animation'),
								child: _buildAnimation(w * scale, h * scale),
							  )
							: KeyedSubtree(
								key: const ValueKey('static'),
								child: _buildStaticImage(w, h),
							  ),
						),
		  ),
		);
	  }),
	);
  }

  Widget _buildStaticImage(double? width, double? height) {
	if (widget.imageAsset.startsWith('http')) {
	  return Image.network(
		widget.imageAsset,
		fit: widget.fit,
		width: width,
		height: height,
	  );
	}
	return Image.asset(
	  widget.imageAsset,
	  fit: widget.fit,
	  width: width,
	  height: height,
	);
  }

  Widget _buildAnimation(double? width, double? height) {
	if (widget.isLottie) {
	  return Lottie.asset(
		widget.animationAsset,
		controller: _lottieController,
		width: width,
		height: height,
		fit: widget.fit,
		onLoaded: (composition) {
		  _lottieController!.duration = composition.duration;
		  _lottieController!.forward();
		  _lottieController!.addStatusListener((status) {
			if (status == AnimationStatus.completed) {
			  _completeAndNavigate();
			}
		  });
		},
	  );
	}

	// For GIFs just use Image.asset/network; navigation is handled by timer
	if (widget.animationAsset.startsWith('http')) {
	  return Image.network(
		widget.animationAsset,
		fit: widget.fit,
		width: width,
		height: height,
	  );
	}

	return Image.asset(
	  widget.animationAsset,
	  fit: widget.fit,
	  width: width,
	  height: height,
	);
  }

}









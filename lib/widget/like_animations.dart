import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Hati Lottie ala Instagram saat double tap gambar:
/// animasi Lottie diputar sambil dibungkus gerakan pop masuk dengan bounce
/// + sedikit miring, diam sebentar, lalu mengecil, naik ke atas, dan memudar.
///
/// Panggil [HeartPopOverlayState.play] lewat GlobalKey untuk memutar ulang.
class HeartPopOverlay extends StatefulWidget {
  final double size;
  final String lottieAsset;

  const HeartPopOverlay({
    super.key,
    this.size = 180,
    this.lottieAsset = 'lib/assets/like_animation.json',
  });

  @override
  State<HeartPopOverlay> createState() => HeartPopOverlayState();
}

class HeartPopOverlayState extends State<HeartPopOverlay>
    with TickerProviderStateMixin {
  // Mengatur gerakan (scale, miring, naik, fade)
  late final AnimationController _controller;
  // Mengatur jalannya frame animasi Lottie
  late final AnimationController _lottieController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _lift;
  late final Animation<double> _tiltProgress;

  final _random = math.Random();
  double _tilt = 0;
  bool _visible = false;
  bool _lottieReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _lottieController = AnimationController(vsync: this);

    _scale = TweenSequence<double>([
      // Pop masuk melewati ukuran normal
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      // Memantul balik
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      // Tahan sebentar
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 34),
      // Mengecil sambil terbang
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.55)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    _lift = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -90.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Miring di awal lalu kembali tegak
    _tiltProgress = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: -0.4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.4, end: 0.0), weight: 16),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 64),
    ]).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });
  }

  /// Putar animasi dari awal. Aman dipanggil berulang (double tap cepat).
  void play() {
    // Arah miring acak kiri/kanan, 10–20 derajat
    final degrees = 10 + _random.nextDouble() * 10;
    _tilt = (_random.nextBool() ? 1 : -1) * degrees * math.pi / 180;
    setState(() => _visible = true);
    _controller.forward(from: 0);
    if (_lottieReady) {
      _lottieController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, _lift.value),
              child: Transform.rotate(
                angle: _tilt * _tiltProgress.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Lottie.asset(
          widget.lottieAsset,
          controller: _lottieController,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          repeat: false,
          onLoaded: (composition) {
            _lottieController.duration = composition.duration;
            _lottieReady = true;
            _lottieController.forward(from: 0);
          },
        ),
      ),
    );
  }
}

/// Ikon like di baris aksi yang memantul saat berubah menjadi "liked".
class AnimatedLikeIcon extends StatefulWidget {
  final bool isLiked;
  final double size;
  final Color likedColor;
  final Color unlikedColor;

  const AnimatedLikeIcon({
    super.key,
    required this.isLiked,
    this.size = 26,
    this.likedColor = const Color(0xFFF43F5E),
    this.unlikedColor = const Color(0xFF374151),
  });

  @override
  State<AnimatedLikeIcon> createState() => _AnimatedLikeIconState();
}

class _AnimatedLikeIconState extends State<AnimatedLikeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.7)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedLikeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLiked && widget.isLiked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.isLiked ? Icons.favorite : Icons.favorite_border_rounded,
        color: widget.isLiked ? widget.likedColor : widget.unlikedColor,
        size: widget.size,
      ),
    );
  }
}


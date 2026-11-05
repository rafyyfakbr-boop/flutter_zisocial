import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedNavItem {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final int badgeCount;

  const AnimatedNavItem({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Custom Bottom Bar dengan efek:
/// "The tapped icon fills violet-cyan from its center, pops, and gains a dot."
class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AnimatedNavItem> items;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _NavButton(
                  item: items[index],
                  isSelected: currentIndex == index,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final AnimatedNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  // Violet → Cyan gradient
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _unselectedColor = Color(0xFF6B7280);

  late final AnimationController _controller;
  late final Animation<double> _fillRadius;
  late final Animation<double> _popScale;
  late final Animation<double> _dotScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      value: widget.isSelected ? 1.0 : 0.0,
    );

    // Fill menyebar dari titik tengah ikon ke pinggir (0 -> 1)
    _fillRadius = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );

    // Efek pop (mengecil sedikit -> membesar 1.25x -> kembali 1.0x)
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.26,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.26,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // Titik indikator (dot) muncul dengan bounce di bawah ikon
    _dotScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant _NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (oldWidget.isSelected && !widget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.isSelected) {
          // Putar ulang efek pop jika tab aktif ditekan lagi
          _controller.forward(from: 0.0);
        }
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = widget.isSelected ? _popScale.value : 1.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 1. Ikon outline dasar (abu-abu)
                    Icon(
                      widget.item.outlineIcon,
                      size: 26,
                      color: _unselectedColor.withValues(
                        alpha: (1.0 - _fillRadius.value * 0.85).clamp(0.0, 1.0),
                      ),
                    ),

                    // 2. Ikon filled bergradasi Violet-Cyan yang mengembang dari tengah
                    if (_fillRadius.value > 0.01)
                      ClipOval(
                        clipper: _CenterCircleClipper(_fillRadius.value),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_violet, _indigo, _cyan],
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Icon(
                            widget.item.filledIcon,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    // 3. Badge pesan belum dibaca (jika ada)
                    if (widget.item.badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_violet, _cyan],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            widget.item.badgeCount > 99
                                ? '99+'
                                : widget.item.badgeCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // 4. Titik (dot) bergradasi Violet-Cyan di bawah ikon aktif
              Transform.scale(
                scale: _dotScale.value.clamp(0.0, 1.3),
                child: Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [_violet, _cyan]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Clipper lingkaran yang tumbuh dari titik pusat widget (progress 0.0 -> 1.0).
class _CenterCircleClipper extends CustomClipper<Rect> {
  final double progress;

  _CenterCircleClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    return Rect.fromCircle(
      center: center,
      radius: maxRadius * progress.clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldReclip(covariant _CenterCircleClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

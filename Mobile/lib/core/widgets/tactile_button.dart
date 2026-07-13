import 'package:flutter/material.dart';

class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TactileButton({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => _controller.reverse(),
      onPointerUp: (_) => _controller.forward(),
      onPointerCancel: (_) => _controller.forward(),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _controller.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

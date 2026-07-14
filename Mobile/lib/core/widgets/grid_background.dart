import 'package:flutter/material.dart';

class GridBackground extends StatelessWidget {
  final Widget child;
  final double spacing;

  const GridBackground({
    super.key,
    required this.child,
    this.spacing = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

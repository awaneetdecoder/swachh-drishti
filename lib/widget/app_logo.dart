import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double radius;
  final double iconSize;

  const AppLogo({super.key, this.radius = 40, this.iconSize = 40});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: Icon(
        Icons.energy_savings_leaf_outlined,
        size: iconSize,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

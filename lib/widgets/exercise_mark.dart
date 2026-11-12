import 'package:flutter/material.dart';

class ExerciseMark extends StatelessWidget {
  final String name;
  final double size;
  const ExerciseMark(this.name, {super.key, this.size = 42});
  @override
  Widget build(BuildContext context) {
    final leg = RegExp('腿|倒蹬|深蹲|硬拉').hasMatch(name);
    final back = RegExp('拉|划船|飞鸟').hasMatch(name) && !leg;
    final cardio = RegExp('走|跑|散步|有氧').hasMatch(name);
    final core = RegExp('腹|核心').hasMatch(name);
    final color = cardio
        ? const Color(0xFFB97647)
        : leg
            ? const Color(0xFF7A719A)
            : back
                ? const Color(0xFF527A99)
                : core
                    ? const Color(0xFF9B8352)
                    : const Color(0xFF587D54);
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(size * .28)),
        child: Icon(
            cardio
                ? Icons.directions_walk_rounded
                : leg
                    ? Icons.airline_seat_legroom_extra_rounded
                    : back
                        ? Icons.rowing_rounded
                        : core
                            ? Icons.accessibility_new_rounded
                            : Icons.fitness_center_rounded,
            size: size * .49,
            color: color));
  }
}

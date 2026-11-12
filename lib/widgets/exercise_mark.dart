import 'package:flutter/material.dart';

/// Small equipment illustrations, kept local so the library works offline.
class ExerciseMark extends StatelessWidget {
  final String name;
  final double size;
  const ExerciseMark(this.name, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final kind = _kind(name);
    final colors = [
      const Color(0xFF497961),
      const Color(0xFF6586A0),
      const Color(0xFF887AA0),
      const Color(0xFFB48C58),
      const Color(0xFFB57D60),
    ];
    final color = colors[switch (kind) {
      'pull' || 'row' || 'rear' => 1,
      'leg' || 'hinge' => 2,
      'core' => 3,
      'walk' => 4,
      _ => 0,
    }];
    return ExcludeSemantics(
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(size * .25)),
          child: CustomPaint(painter: _EquipmentPainter(kind, color))),
    );
  }

  String _kind(String value) {
    if (RegExp('走|跑|散步|有氧|椭圆|单车|划船机|放松').hasMatch(value)) return 'walk';
    if (RegExp('腹|核心|平板支撑|死虫|鸟狗|举腿').hasMatch(value)) return 'core';
    if (value.contains('硬拉')) return 'hinge';
    if (RegExp('腿|倒蹬|深蹲|臀|提踵|外展').hasMatch(value)) return 'leg';
    if (RegExp('下拉|引体').hasMatch(value)) return 'pull';
    if (value.contains('划船')) return 'row';
    if (RegExp('飞鸟|面拉').hasMatch(value)) return 'rear';
    if (value.contains('侧平举')) return 'raise';
    if (value.contains('弯举')) return 'curl';
    if (value.contains('下压')) return 'cable';
    if (value.contains('肩推')) return 'shoulder';
    if (value.contains('上斜')) return 'incline';
    if (value.contains('俯卧撑')) return 'pushup';
    if (RegExp('卧推|推胸').hasMatch(value)) return 'bench';
    return 'weights';
  }
}

class _EquipmentPainter extends CustomPainter {
  final String kind;
  final Color color;
  _EquipmentPainter(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final ink = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final soft = Paint()..color = color.withValues(alpha: .17);
    void line(double a, double b, double c, double d) =>
        canvas.drawLine(Offset(a, b), Offset(c, d), ink);
    void bar(double x, double y, {double angle = 0}) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      line(-11, 0, 11, 0);
      for (final side in [-1.0, 1.0]) {
        final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(side * 8, 0), width: 4, height: 12),
            const Radius.circular(1.5));
        canvas.drawRRect(rect, soft);
        canvas.drawRRect(rect, ink);
      }
      canvas.restore();
    }

    void head(double x, double y) => canvas.drawCircle(Offset(x, y), 3.5, ink);
    canvas.drawOval(const Rect.fromLTWH(10, 49, 44, 4), soft);
    switch (kind) {
      case 'bench':
      case 'incline':
        final incline = kind == 'incline';
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(17, incline ? 34 : 37, 28, 5),
                const Radius.circular(2)),
            soft);
        line(18, 40, 46, 40);
        line(22, 40, 19, 49);
        line(42, 40, 46, 49);
        line(14, 21, 14, 48);
        line(50, 21, 50, 48);
        bar(32, 24);
        if (incline) line(22, 35, 37, 29);
      case 'shoulder':
        line(26, 32, 26, 42);
        line(26, 42, 41, 42);
        line(29, 43, 25, 50);
        line(38, 43, 42, 50);
        head(32, 24);
        line(32, 29, 32, 38);
        line(32, 32, 22, 28);
        line(22, 28, 20, 20);
        line(32, 32, 42, 28);
        line(42, 28, 44, 20);
        bar(18, 17, angle: 1.57);
        bar(46, 17, angle: 1.57);
      case 'pull':
      case 'cable':
        line(17, 48, 17, 15);
        line(17, 15, 46, 15);
        line(46, 15, 46, 48);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(39, 30, 6, 14), const Radius.circular(1)),
            soft);
        line(31, 16, 31, 27);
        line(22, 29, 31, 26);
        line(31, 26, 40, 29);
        if (kind == 'pull') {
          line(24, 43, 37, 43);
          line(30, 43, 30, 49);
        } else {
          line(24, 37, 37, 37);
          line(26, 41, 35, 41);
        }
      case 'row':
        line(14, 44, 49, 44);
        line(18, 44, 16, 49);
        line(41, 44, 44, 49);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(19, 37, 14, 5), const Radius.circular(2)),
            soft);
        line(47, 43, 47, 21);
        line(29, 30, 47, 30);
        line(25, 27, 25, 33);
        head(22, 21);
        line(22, 26, 25, 37);
        line(25, 37, 36, 37);
        line(36, 37, 40, 43);
      case 'leg':
        line(16, 43, 27, 43);
        line(16, 43, 12, 29);
        line(23, 43, 20, 49);
        line(29, 43, 49, 18);
        line(36, 47, 54, 23);
        line(43, 19, 54, 28);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(10, 28, 5, 14), const Radius.circular(2)),
            soft);
        canvas.drawCircle(const Offset(42, 30), 4, soft);
        canvas.drawCircle(const Offset(42, 30), 4, ink);
      case 'core':
        head(30, 18);
        line(30, 24, 26, 34);
        line(26, 34, 35, 39);
        line(35, 39, 40, 48);
        line(30, 27, 40, 31);
        line(40, 31, 44, 24);
        line(17, 42, 33, 42);
        line(23, 42, 20, 49);
        line(18, 23, 18, 40);
        line(18, 23, 23, 23);
      case 'walk':
        head(33, 15);
        line(32, 21, 29, 33);
        line(30, 26, 22, 29);
        line(22, 29, 18, 26);
        line(31, 24, 39, 28);
        line(39, 28, 44, 25);
        line(29, 33, 23, 40);
        line(23, 40, 17, 46);
        line(29, 33, 35, 39);
        line(35, 39, 39, 48);
        line(11, 50, 52, 50);
      case 'rear':
        head(32, 19);
        line(32, 25, 32, 42);
        line(32, 29, 18, 24);
        line(32, 29, 46, 24);
        line(32, 42, 23, 49);
        line(32, 42, 41, 49);
        bar(16, 23, angle: 1.2);
        bar(48, 23, angle: -1.2);
      case 'pushup':
        head(19, 27);
        line(24, 30, 43, 34);
        line(29, 31, 27, 43);
        line(27, 43, 20, 43);
        line(43, 34, 50, 43);
        line(13, 48, 53, 48);
      case 'weights':
      case 'raise':
      case 'curl':
      case 'hinge':
        bar(23, 27, angle: kind == 'hinge' ? -.3 : -.6);
        bar(42, 38, angle: kind == 'curl' ? -.6 : .6);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EquipmentPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

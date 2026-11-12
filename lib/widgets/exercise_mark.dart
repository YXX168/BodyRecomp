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
      const Color(0xFF518C83),
      const Color(0xFF7396B8),
      const Color(0xFF9586B9),
      const Color(0xFFBD9862),
      const Color(0xFFC68E7C),
    ];
    final color = colors[switch (kind) {
      'pull' || 'row' || 'rear' || 'fly' => 1,
      'leg' || 'hinge' => 2,
      'core' || 'plank' => 3,
      'walk' || 'cycle' || 'erg' || 'cardio' || 'stretch' => 4,
      _ => 0,
    }];
    return ExcludeSemantics(
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(size * .25)),
          child: CustomPaint(painter: _EquipmentPainter(kind, color))),
    );
  }

  String _kind(String value) {
    if (RegExp('单车|自行车').hasMatch(value)) return 'cycle';
    if (value.contains('划船机')) return 'erg';
    if (RegExp('拉伸|放松').hasMatch(value)) return 'stretch';
    if (RegExp('椭圆|有氧').hasMatch(value)) return 'cardio';
    if (RegExp('走|跑|散步').hasMatch(value)) return 'walk';
    if (value.contains('平板支撑')) return 'plank';
    if (RegExp('腹|核心|平板支撑|死虫|鸟狗|举腿').hasMatch(value)) return 'core';
    if (value.contains('硬拉')) return 'hinge';
    if (RegExp('腿|倒蹬|深蹲|臀|提踵|外展').hasMatch(value)) return 'leg';
    if (RegExp('下拉|引体').hasMatch(value)) return 'pull';
    if (value.contains('划船')) return 'row';
    if (RegExp('飞鸟|面拉').hasMatch(value)) return 'rear';
    if (value.contains('侧平举')) return 'raise';
    if (value.contains('弯举')) return 'curl';
    if (value.contains('下压')) return 'cable';
    if (value.contains('臂屈伸')) return 'triceps';
    if (value.contains('夹胸')) return 'fly';
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
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color.withValues(alpha: .22);
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), ink);
    void path(List<Offset> points) {
      final shape = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        shape.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(shape, ink);
    }

    void pad(double x, double y, double w, double h) {
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h), const Radius.circular(2));
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, ink);
    }

    void ring(double x, double y, double r) =>
        canvas.drawCircle(Offset(x, y), r, ink);
    void head(double x, double y) => ring(x, y, 3.5);
    void bar(double x, double y, {double angle = 0, double scale = 1}) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.scale(scale);
      line(-14, 0, 14, 0);
      pad(-11, -6, 4, 12);
      pad(7, -6, 4, 12);
      canvas.restore();
    }

    void mat() => pad(11, 46, 42, 4);
    switch (kind) {
      case 'bench':
        bar(32, 21);
        line(15, 16, 15, 45);
        line(49, 16, 49, 45);
        pad(19, 34, 26, 5);
        line(23, 39, 20, 49);
        line(41, 39, 44, 49);
      case 'incline':
        bar(34, 18, scale: .85);
        canvas.save();
        canvas.translate(28, 34);
        canvas.rotate(-.65);
        pad(-9, -2, 23, 5);
        canvas.restore();
        pad(17, 39, 12, 4);
        line(23, 43, 20, 49);
        line(33, 34, 44, 49);
      case 'shoulder':
        bar(32, 17, scale: .85);
        line(23, 20, 23, 28);
        line(41, 20, 41, 28);
        line(23, 28, 28, 31);
        line(41, 28, 36, 31);
        pad(27, 29, 10, 12);
        pad(25, 42, 17, 4);
        line(29, 46, 26, 51);
        line(38, 46, 42, 51);
      case 'pull':
      case 'cable':
        path(const [
          Offset(16, 49),
          Offset(16, 14),
          Offset(48, 14),
          Offset(48, 49)
        ]);
        ring(32, 17, 2);
        line(32, 20, 32, kind == 'pull' ? 27 : 34);
        if (kind == 'pull') {
          path(const [
            Offset(22, 30),
            Offset(27, 27),
            Offset(37, 27),
            Offset(42, 30)
          ]);
          pad(23, 42, 14, 4);
          line(30, 46, 30, 50);
        } else {
          path(const [Offset(26, 40), Offset(32, 34), Offset(38, 40)]);
          ring(25, 41, 1);
          ring(39, 41, 1);
        }
        pad(42, 31, 6, 13);
        line(42, 36, 48, 36);
        line(42, 40, 48, 40);
      case 'row':
        pad(13, 37, 18, 5);
        line(18, 42, 15, 49);
        line(27, 42, 30, 49);
        line(43, 20, 43, 46);
        pad(43, 22, 7, 20);
        line(25, 29, 43, 29);
        pad(21, 26, 4, 7);
        line(34, 43, 40, 36);
        line(13, 49, 51, 49);
      case 'leg':
        canvas.save();
        canvas.translate(22, 36);
        canvas.rotate(-.75);
        pad(0, 0, 32, 5);
        line(2, 9, 33, 9);
        pad(27, -8, 5, 16);
        canvas.restore();
        path(const [Offset(12, 29), Offset(16, 43), Offset(28, 43)]);
        line(19, 43, 16, 50);
        line(30, 40, 43, 50);
        line(12, 50, 50, 50);
      case 'hinge':
        head(43, 20);
        path(const [
          Offset(38, 24),
          Offset(25, 32),
          Offset(27, 42),
          Offset(23, 50)
        ]);
        path(const [Offset(25, 32), Offset(34, 41), Offset(38, 50)]);
        line(35, 26, 39, 39);
        bar(40, 43, scale: .65);
      case 'raise':
      case 'rear':
        head(32, 19);
        line(32, 26, 32, 42);
        line(32, 42, 25, 50);
        line(32, 42, 39, 50);
        final y = kind == 'raise' ? 29.0 : 24.0;
        path([const Offset(32, 28), Offset(22, y), Offset(14, y - 2)]);
        path([const Offset(32, 28), Offset(42, y), Offset(50, y - 2)]);
        if (kind == 'raise') {
          pad(10, y - 6, 5, 8);
          pad(49, y - 6, 5, 8);
        } else {
          line(11, 34, 17, 31);
          line(53, 34, 47, 31);
        }
      case 'fly':
        pad(27, 24, 10, 20);
        pad(23, 44, 18, 4);
        path(const [Offset(28, 30), Offset(17, 26), Offset(17, 18)]);
        path(const [Offset(36, 30), Offset(47, 26), Offset(47, 18)]);
        line(13, 18, 21, 18);
        line(43, 18, 51, 18);
        line(31, 48, 31, 52);
      case 'curl':
        path(const [Offset(18, 45), Offset(29, 43), Offset(39, 28)]);
        path(const [Offset(18, 35), Offset(25, 35), Offset(31, 25)]);
        bar(36, 21, angle: -.5, scale: .8);
        line(18, 35, 18, 45);
      case 'triceps':
        head(30, 31);
        line(30, 38, 30, 50);
        path(const [Offset(24, 39), Offset(19, 23), Offset(32, 17)]);
        path(const [Offset(36, 39), Offset(42, 23), Offset(32, 17)]);
        bar(32, 16, scale: .65);
      case 'core':
        mat();
        head(17, 35);
        path(const [
          Offset(22, 38),
          Offset(31, 42),
          Offset(38, 28),
          Offset(49, 38)
        ]);
        path(const [Offset(24, 37), Offset(32, 31), Offset(39, 33)]);
      case 'pushup':
      case 'plank':
        mat();
        head(16, 28);
        path(const [Offset(21, 31), Offset(40, 35), Offset(50, 44)]);
        if (kind == 'pushup') {
          path(const [Offset(27, 32), Offset(24, 43), Offset(17, 43)]);
        } else {
          path(const [Offset(27, 32), Offset(29, 42), Offset(19, 42)]);
        }
      case 'walk':
        head(34, 16);
        path(const [Offset(33, 23), Offset(29, 35), Offset(20, 48)]);
        path(const [Offset(29, 35), Offset(38, 41), Offset(42, 49)]);
        path(const [Offset(32, 26), Offset(23, 31), Offset(19, 28)]);
        path(const [Offset(32, 26), Offset(40, 30), Offset(46, 26)]);
      case 'cycle':
        ring(18, 43, 9);
        ring(47, 43, 9);
        path(const [
          Offset(18, 43),
          Offset(27, 29),
          Offset(35, 43),
          Offset(18, 43)
        ]);
        path(const [Offset(35, 43), Offset(42, 27), Offset(47, 43)]);
        line(24, 26, 31, 26);
        line(27, 26, 27, 29);
        path(const [Offset(42, 27), Offset(40, 20), Offset(47, 20)]);
      case 'erg':
        ring(16, 35, 8);
        pad(28, 32, 12, 5);
        line(23, 40, 52, 40);
        line(31, 37, 31, 40);
        line(16, 27, 39, 23);
        line(39, 20, 39, 26);
        line(14, 43, 11, 48);
        line(48, 40, 52, 48);
      case 'cardio':
        line(16, 48, 49, 48);
        canvas.drawOval(const Rect.fromLTWH(20, 34, 27, 11), ink);
        line(27, 35, 35, 23);
        line(35, 23, 35, 16);
        line(42, 35, 46, 19);
        line(43, 19, 49, 19);
        line(24, 40, 16, 26);
        line(13, 26, 19, 26);
      case 'stretch':
        mat();
        head(35, 23);
        path(const [Offset(33, 29), Offset(27, 39), Offset(43, 43)]);
        path(const [Offset(28, 36), Offset(39, 36), Offset(48, 42)]);
        path(const [Offset(27, 39), Offset(18, 43), Offset(13, 43)]);
      default:
        bar(32, 32, angle: -.55, scale: 1.3);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EquipmentPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

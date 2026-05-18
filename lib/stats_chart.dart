import 'dart:math';
import 'package:flutter/material.dart';

class PolygonalStatsChart extends StatelessWidget {
  const PolygonalStatsChart({
    super.key,
    required this.stats,
  });

  /// Основная карта данных пользователя (например, {"taunt_strength": 78.5, "taunt_speed": 60.0})
  final Map<String, double> stats;

  @override
  Widget build(BuildContext context) {
    // Ограничиваем данные ровно 5 метриками
    final userTaunts = Map<String, double>.fromEntries(
      stats.entries.take(5),
    );

    if (userTaunts.length < 3) {
      return const Center(
        child: Text(
          'Requires at least 3 categories to generate data map',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return CustomPaint(
      painter: _PolygonalPainter(
        taunts: userTaunts,
        fillColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _PolygonalPainter extends CustomPainter {
  const _PolygonalPainter({
    required this.taunts,
    required this.fillColor,
    required this.textColor,
  }) : sides = taunts.length;

  final Map<String, double> taunts;
  final Color fillColor;
  final Color textColor;
  final int sides;

  // Вычисление координат точек по осям графа
  Offset _point(Offset center, double radius, int index, double fraction) {
    final angle = -pi / 2 + index * 2 * pi / sides;
    return Offset(
      center.dx + radius * fraction * cos(angle),
      center.dy + radius * fraction * sin(angle),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Небольшое смещение вниз (+18), чтобы оставить место для верхнего текстового лейбла
    final center = Offset(size.width / 2, (size.height / 2) + 18);
    final radius = size.shortestSide / 2 - 45;
    final keys = taunts.keys.toList();

    // 1. Отрисовка фоновой сетки (концентрические многоугольники)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final p = _point(center, radius, i, frac);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Отрисовка осей, радиально идущих из центра
    final axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.8;

    for (int i = 0; i < sides; i++) {
      canvas.drawLine(center, _point(center, radius, i, 1.0), axisPaint);
    }

    // 3. Отрисовка формы основных данных спортсмена (основной полигон)
    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final statPath = Path();
    for (int i = 0; i < sides; i++) {
      final fraction = (taunts[keys[i]] ?? 0).clamp(0.0, 100.0) / 100;
      final p = _point(center, radius, i, fraction);
      i == 0 ? statPath.moveTo(p.dx, p.dy) : statPath.lineTo(p.dx, p.dy);
    }
    statPath.close();
    canvas.drawPath(statPath, fillPaint);
    canvas.drawPath(statPath, strokePaint);

    // Узловые точки на вершинах многоугольника данных
    final dotPaint = Paint()..color = fillColor;
    for (int i = 0; i < sides; i++) {
      final fraction = (taunts[keys[i]] ?? 0).clamp(0.0, 100.0) / 100;
      canvas.drawCircle(_point(center, radius, i, fraction), 4, dotPaint);
    }

    // 4. Отрисовка динамических текстовых меток вокруг осей
    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * 2 * pi / sides;
      final labelRadius = radius + 26; 
      final lx = center.dx + labelRadius * cos(angle);
      final ly = center.dy + labelRadius * sin(angle);
      
      final name = keys[i].split('_').last.toUpperCase();
      final value = "${taunts[keys[i]]!.toStringAsFixed(0)}%";

      _drawText(canvas, name, Offset(lx, ly - 8), fontSize: 11, bold: true);
      _drawText(canvas, value, Offset(lx, ly + 8), fontSize: 11);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position,
      {double fontSize = 14, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_PolygonalPainter old) =>
      old.taunts != taunts ||
      old.fillColor != fillColor ||
      old.textColor != textColor;
}
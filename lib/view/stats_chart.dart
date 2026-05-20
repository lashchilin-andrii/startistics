import 'dart:math';
import 'package:flutter/material.dart';
import 'package:startistics/util/format_taunt_name.dart';

class PolygonalStatsChart extends StatelessWidget {
  const PolygonalStatsChart({super.key, required this.stats});

  /// Карта данных пользователя. Поддерживает любое количество категорий (от 3 до бесконечности).
  final Map<String, double> stats;

  @override
  Widget build(BuildContext context) {
    final userTaunts = Map<String, double>.from(stats);

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
    // Центрируем график. Смещение вниз убрано, так как отступы теперь считаются динамически
    final center = Offset(size.width / 2, size.height / 2);

    // Динамический отступ для текста: чем больше сторон, тем аккуратнее должны быть отступы
    final double padding = sides > 7 ? 55 : 45;
    final radius = size.shortestSide / 2 - padding;
    final keys = taunts.keys.toList();

    // 1. Отрисовка фоновой сетки (концентрические многоугольники)
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
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
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.8;

    for (int i = 0; i < sides; i++) {
      canvas.drawLine(center, _point(center, radius, i, 1.0), axisPaint);
    }

    // 3. Отрисовка формы основных данных спортсмена (основной полигон)
    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.25)
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

    if (sides > 0) {
      statPath.close();
      canvas.drawPath(statPath, fillPaint);
      canvas.drawPath(statPath, strokePaint);
    }

    // Узловые точки на вершинах многоугольника данных
    final dotPaint = Paint()..color = fillColor;
    for (int i = 0; i < sides; i++) {
      final fraction = (taunts[keys[i]] ?? 0).clamp(0.0, 100.0) / 100;
      canvas.drawCircle(_point(center, radius, i, fraction), 4, dotPaint);
    }

    // 4. Отрисовка динамических текстовых меток вокруг осей
    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * 2 * pi / sides;

      // Смещаем текст чуть дальше от края графика (на 22 пикселя)
      final labelRadius = radius + 22;
      final lx = center.dx + labelRadius * cos(angle);
      final ly = center.dy + labelRadius * sin(angle);

      final String rawName = keys[i].contains('_')
          ? keys[i].split('_').last.toUpperCase()
          : keys[i].toUpperCase();
      final name = formatTauntName(rawName);

      final value = "${taunts[keys[i]]!.toStringAsFixed(0)}%";
      // Чтобы текст не накладывался друг на друга при 8+ осях,
      // выстраиваем имя и проценты в одну строку, если параметров много.
      if (sides > 6) {
        _drawText(
          canvas,
          "$name: $value",
          Offset(lx, ly),
          fontSize: 10,
          bold: true,
          angle: angle,
        );
      } else {
        _drawText(
          canvas,
          name,
          Offset(lx, ly - 7),
          fontSize: 11,
          bold: true,
          angle: angle,
        );
        _drawText(
          canvas,
          value,
          Offset(lx, ly + 7),
          fontSize: 11,
          angle: angle,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    double fontSize = 14,
    bool bold = false,
    required double angle,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: textColor,
          letterSpacing: 0.5,
        ),
        text: text,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    // Умное выравнивание: смещаем точку привязки текста в зависимости от того,
    // с какой стороны от центра находится ось (слева, справа, сверху или снизу)
    final cosA = cos(angle);
    final sinA = sin(angle);

    final adjustedX = position.dx - tp.width / 2 + (cosA * (tp.width / 2));
    final adjustedY = position.dy - tp.height / 2 + (sinA * (tp.height / 2));

    tp.paint(canvas, Offset(adjustedX, adjustedY));
  }

  @override
  bool shouldRepaint(_PolygonalPainter old) =>
      old.taunts != taunts ||
      old.fillColor != fillColor ||
      old.textColor != textColor;
}

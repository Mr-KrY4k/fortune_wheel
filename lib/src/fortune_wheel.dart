import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'fortune_wheel_theme.dart';
import 'wheel_section.dart';

class FortuneWheelGame extends FlameGame with TapDetector {
  late FortuneWheel wheel;
  Function(SectionType)? onResult;
  final double spinDuration;
  final PointerPosition pointerPosition;
  final double pointerOffset;
  final int sectionsCount;
  final bool showSectionIndex;
  final FortuneWheelTheme theme;

  FortuneWheelGame({
    this.onResult,
    this.spinDuration = 3.0,
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.sectionsCount = 10,
    this.showSectionIndex = false,
    this.theme = const FortuneWheelTheme(),
  });

  @override
  Color backgroundColor() => theme.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    wheel = FortuneWheel(
      sections: _createSections(),
      spinDuration: spinDuration,
      pointerPosition: pointerPosition,
      pointerOffset: pointerOffset,
      showSectionIndex: showSectionIndex,
      theme: theme,
      onSpinComplete: (result) {
        onResult?.call(result);
      },
    );

    add(wheel);
  }

  List<WheelSection> _createSections() {
    final colors = theme.sectionsTheme.colors;
    return List.generate(sectionsCount, (index) {
      final isWin = index.isEven;
      final colorIndex = index % colors.length;
      return WheelSection(
        type: isWin ? SectionType.win : SectionType.lose,
        color: colors[colorIndex],
        label: isWin ? 'Выиграл' : 'Не выиграл',
      );
    });
  }

  @override
  void onTapDown(TapDownInfo info) {
    wheel.spin();
  }

  /// Программно запускает вращение на конкретную секцию
  /// [duration] - время вращения в секундах (опционально)
  void spinToSection(int sectionIndex, {double? duration}) {
    wheel.spin(targetSection: sectionIndex, duration: duration);
  }

  /// Программно запускает вращение на случайную секцию "Выиграл"
  /// [duration] - время вращения в секундах (опционально)
  void spinToWin({double? duration}) {
    // Находим все секции с типом win (четные индексы)
    final winSections = <int>[];
    for (int i = 0; i < wheel.sections.length; i++) {
      if (wheel.sections[i].type == SectionType.win) {
        winSections.add(i);
      }
    }
    if (winSections.isNotEmpty) {
      final randomWinIndex =
          winSections[math.Random().nextInt(winSections.length)];
      wheel.spin(targetSection: randomWinIndex, duration: duration);
    }
  }

  /// Программно запускает вращение на случайную секцию "Не выиграл"
  /// [duration] - время вращения в секундах (опционально)
  void spinToLose({double? duration}) {
    // Находим все секции с типом lose (нечетные индексы)
    final loseSections = <int>[];
    for (int i = 0; i < wheel.sections.length; i++) {
      if (wheel.sections[i].type == SectionType.lose) {
        loseSections.add(i);
      }
    }
    if (loseSections.isNotEmpty) {
      final randomLoseIndex =
          loseSections[math.Random().nextInt(loseSections.length)];
      wheel.spin(targetSection: randomLoseIndex, duration: duration);
    }
  }
}

class FortuneWheel extends PositionComponent
    with HasGameReference<FortuneWheelGame> {
  final List<WheelSection> sections;
  final Function(SectionType) onSpinComplete;
  final double spinDuration;
  final PointerPosition pointerPosition;
  final double pointerOffset;
  final bool showSectionIndex;
  final FortuneWheelTheme theme;

  double currentRotation = 0;
  double rotationSpeed = 0;
  bool isSpinning = false;
  int? resultIndex;
  double elapsedTime = 0;
  double initialSpeed = 0;
  double? targetRotation;
  int? targetSectionIndex;
  double currentSpinDuration = 3.0;
  double startRotation = 0;

  FortuneWheel({
    required this.sections,
    required this.onSpinComplete,
    this.spinDuration = 3.0,
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.showSectionIndex = false,
    this.theme = const FortuneWheelTheme(),
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final availableSize = math.min(game.size.x, game.size.y) - 50;
    size = Vector2.all(availableSize);
    position = game.size / 2;
    anchor = Anchor.center;
  }

  void spin({int? targetSection, double? duration}) {
    if (isSpinning) return;

    isSpinning = true;
    elapsedTime = 0;
    resultIndex = null;
    targetSectionIndex = targetSection;
    startRotation = currentRotation;

    currentSpinDuration = duration ?? spinDuration;

    if (targetSectionIndex != null) {
      // Рассчитываем целевой угол для остановки на конкретной секции
      final sectionAngle = (2 * math.pi) / sections.length;

      // Центр целевой секции (в системе координат колеса без поворота)
      var targetSectionCenter =
          targetSectionIndex! * sectionAngle - math.pi / 2 + sectionAngle / 2;
      // Нормализуем к [0, 2π)
      targetSectionCenter = targetSectionCenter % (2 * math.pi);
      if (targetSectionCenter < 0) targetSectionCenter += 2 * math.pi;

      // Угол указателя в абсолютной системе координат
      double pointerAngle;
      switch (pointerPosition) {
        case PointerPosition.top:
          pointerAngle = -math.pi / 2;
          break;
        case PointerPosition.bottom:
          pointerAngle = math.pi / 2;
          break;
        case PointerPosition.left:
          pointerAngle = math.pi;
          break;
        case PointerPosition.right:
          pointerAngle = 0;
          break;
      }

      // Нормализуем pointerAngle тоже
      var normalizedPointerAngle = pointerAngle % (2 * math.pi);
      if (normalizedPointerAngle < 0) normalizedPointerAngle += 2 * math.pi;

      // Нужно повернуть так, чтобы: targetSectionCenter + targetRotation = normalizedPointerAngle (mod 2π)
      // targetRotation = normalizedPointerAngle - targetSectionCenter (mod 2π)
      var baseRotation = normalizedPointerAngle - targetSectionCenter;

      // Добавляем небольшое случайное отклонение от центра секции (±30% от половины секции)
      final randomOffset =
          (math.Random().nextDouble() - 0.5) * sectionAngle * 0.6;
      baseRotation += randomOffset;

      // Нормализуем baseRotation к [0, 2π)
      baseRotation = baseRotation % (2 * math.pi);
      if (baseRotation < 0) baseRotation += 2 * math.pi;

      // Добавляем минимум 3 ЦЕЛЫХ полных оборота (важно для точности!)
      final extraRotations = (3 + math.Random().nextInt(3))
          .toDouble(); // 3, 4, или 5 целых оборотов

      // Находим ближайший угол больше текущего
      while (baseRotation <= currentRotation) {
        baseRotation += 2 * math.pi;
      }

      targetRotation = baseRotation + extraRotations * 2 * math.pi;
      initialSpeed =
          (targetRotation! - currentRotation) / currentSpinDuration * 2;
      rotationSpeed = initialSpeed;

      // Проверяем правильность расчета
      var finalAngle = targetSectionCenter + targetRotation!;
      var normalizedFinal = finalAngle % (2 * math.pi);
      if (normalizedFinal < 0) normalizedFinal += 2 * math.pi;
      var normalizedPointer = pointerAngle % (2 * math.pi);
      if (normalizedPointer < 0) normalizedPointer += 2 * math.pi;

      print('=== SPIN TO SECTION $targetSectionIndex ===');
      print('currentSpinDuration: ${currentSpinDuration}s');
      print('sectionAngle: ${sectionAngle * 180 / math.pi}°');
      print(
        'targetSectionCenter (norm): ${targetSectionCenter * 180 / math.pi}°',
      );
      print('pointerAngle (norm): ${normalizedPointerAngle * 180 / math.pi}°');
      print('baseRotation: ${baseRotation * 180 / math.pi}°');
      print('targetRotation: ${targetRotation! * 180 / math.pi}°');
      print('startRotation: ${startRotation * 180 / math.pi}°');
      print(
        'После поворота центр секции: ${normalizedFinal * 180 / math.pi}° (нормализовано)',
      );
      print(
        'Должен быть на: ${normalizedPointer * 180 / math.pi}° (нормализовано)',
      );
      print(
        'Разница: ${((normalizedFinal - normalizedPointer).abs() * 180 / math.pi)}°',
      );
    } else {
      // Случайное вращение
      initialSpeed = 15 + math.Random().nextDouble() * 10;
      rotationSpeed = initialSpeed;

      // Рассчитываем целевой угол для случайного вращения
      // чтобы анимация была похожа на целевое вращение
      final randomRotation = initialSpeed * currentSpinDuration / 2;
      targetRotation = currentRotation + randomRotation;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isSpinning) {
      elapsedTime += dt;

      final progress = math.min(elapsedTime / currentSpinDuration, 1.0);

      // Используем одинаковое замедление для всех типов вращения
      rotationSpeed = initialSpeed * (1 - progress);
      currentRotation += rotationSpeed * dt;

      if (progress >= 1.0) {
        isSpinning = false;
        rotationSpeed = 0;

        // Точно устанавливаем финальную позицию для целевого вращения
        if (targetSectionIndex != null && targetRotation != null) {
          currentRotation = targetRotation!;
        }

        _calculateResult();
      }
    }
  }

  void _calculateResult() {
    final sectionAngle = (2 * math.pi) / sections.length;

    // Угол указателя
    double pointerAngle;
    switch (pointerPosition) {
      case PointerPosition.top:
        pointerAngle = -math.pi / 2;
        break;
      case PointerPosition.bottom:
        pointerAngle = math.pi / 2;
        break;
      case PointerPosition.left:
        pointerAngle = math.pi;
        break;
      case PointerPosition.right:
        pointerAngle = 0;
        break;
    }

    // Центр секции i после поворота: (i * sectionAngle - π/2 + sectionAngle/2) + currentRotation = pointerAngle
    // i * sectionAngle = pointerAngle - currentRotation + π/2 - sectionAngle/2
    // i = (pointerAngle - currentRotation + π/2 - sectionAngle/2) / sectionAngle

    var angleForCalc =
        pointerAngle - currentRotation + math.pi / 2 - sectionAngle / 2;

    // Нормализуем
    angleForCalc = angleForCalc % (2 * math.pi);
    if (angleForCalc < 0) angleForCalc += 2 * math.pi;

    var sectionFloat = angleForCalc / sectionAngle;
    resultIndex = sectionFloat.round() % sections.length;

    print('=== RESULT ===');
    print('currentRotation: ${currentRotation * 180 / math.pi}°');
    print('pointerAngle: ${pointerAngle * 180 / math.pi}°');
    print('angleForCalc: ${angleForCalc * 180 / math.pi}°');
    print('sectionFloat: $sectionFloat');
    print('resultIndex: $resultIndex');
    print('section type: ${sections[resultIndex!].type}');
    print('===');

    if (resultIndex != null) {
      onSpinComplete(sections[resultIndex!].type);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size / 2;
    final radius = size.x / 2;
    final scale = radius / 150;

    canvas.save();
    canvas.translate(center.x, center.y);
    canvas.rotate(currentRotation);
    canvas.translate(-center.x, -center.y);

    final sectionAngle = (2 * math.pi) / sections.length;

    for (int i = 0; i < sections.length; i++) {
      final startAngle = i * sectionAngle - math.pi / 2;

      final paint = Paint()
        ..color = sections[i].color
        ..style = PaintingStyle.fill;

      final scaledSectionRadius =
          theme.sectionsTheme.sectionBorderRadius * scale;
      final Path path;

      // Создаем path с учетом скругления
      if (scaledSectionRadius > 0) {
        path = _createRoundedSectionPath(
          center,
          radius,
          startAngle,
          sectionAngle,
          scaledSectionRadius,
        );
      } else {
        path = Path()
          ..moveTo(center.x, center.y)
          ..arcTo(
            Rect.fromCircle(center: Offset(center.x, center.y), radius: radius),
            startAngle,
            sectionAngle,
            false,
          )
          ..close();
      }

      canvas.drawPath(path, paint);

      // Бордер секции (рисуем только если sectionBorderWidth > 0)
      if (theme.sectionsTheme.sectionBorderWidth > 0) {
        final sectionBorderPaint = Paint()
          ..color = theme.sectionsTheme.sectionBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = theme.sectionsTheme.sectionBorderWidth * scale;

        canvas.drawPath(path, sectionBorderPaint);
      }

      _drawText(
        canvas,
        sections[i].label,
        i,
        center,
        radius,
        startAngle + sectionAngle / 2,
        scale,
        showSectionIndex,
      );
    }

    canvas.restore();

    // Бордер колеса (рисуем только если width > 0)
    if (theme.borderTheme.width > 0) {
      final wheelBorderPaint = Paint()
        ..color = theme.borderTheme.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.borderTheme.width * scale;

      canvas.drawCircle(Offset(center.x, center.y), radius, wheelBorderPaint);
    }

    _drawPointer(canvas, center, radius, scale);

    // Центральный круг (вал) - рисуем поверх всего
    if (theme.centerCircleTheme != null) {
      _drawCenterCircle(canvas, center, scale);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    int index,
    Vector2 center,
    double radius,
    double angle,
    double scale,
    bool showIndex,
  ) {
    canvas.save();

    canvas.translate(center.x, center.y);
    canvas.rotate(angle);

    final textTheme = theme.sectionsTheme.textTheme;
    final fontSize = math.max(8.0, textTheme.fontSize * scale);

    if (showIndex) {
      final indexFontSize = math.max(12.0, 20 * scale);
      final indexPainter = TextPainter(
        text: TextSpan(
          text: '$index',
          style: TextStyle(
            color: textTheme.color,
            fontSize: indexFontSize,
            fontWeight: textTheme.fontWeight,
            shadows: textTheme.shadows,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      indexPainter.layout();

      final indexOffset = Offset(
        radius * 0.8 - indexPainter.width / 2,
        -indexPainter.height / 2,
      );

      indexPainter.paint(canvas, indexOffset);

      // Рисуем текст ближе к центру
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textTheme.color,
            fontSize: fontSize,
            fontWeight: textTheme.fontWeight,
            shadows: textTheme.shadows,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final textOffset = Offset(
        radius * 0.4 - textPainter.width / 2,
        -textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    } else {
      // Рисуем только текст по центру секции
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textTheme.color,
            fontSize: fontSize,
            fontWeight: textTheme.fontWeight,
            shadows: textTheme.shadows,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final textOffset = Offset(
        radius * 0.6 - textPainter.width / 2,
        -textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }

    canvas.restore();
  }

  void _drawPointer(
    Canvas canvas,
    Vector2 center,
    double radius,
    double scale,
  ) {
    final pointerTheme = theme.pointerTheme;

    final scaledPointerWidth = math.max(8, pointerTheme.width * scale);
    final scaledPointerHeight = math.max(10, pointerTheme.height * scale);
    final offset = pointerOffset * scale;
    final scaledBorderRadius = pointerTheme.borderRadius * scale;

    final pointerPath = Path();
    Rect? pointerBounds;

    // Создаем треугольник со скругленными углами если borderRadius > 0
    switch (pointerPosition) {
      case PointerPosition.top:
        final tip = Offset(center.x, center.y - radius + offset);
        final left = Offset(
          center.x - scaledPointerWidth,
          center.y - radius - scaledPointerHeight + offset,
        );
        final right = Offset(
          center.x + scaledPointerWidth,
          center.y - radius - scaledPointerHeight + offset,
        );

        if (scaledBorderRadius > 0) {
          _addRoundedTriangle(
            pointerPath,
            tip,
            left,
            right,
            scaledBorderRadius,
          );
        } else {
          pointerPath
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
        }

        pointerBounds = Rect.fromLTRB(
          center.x - scaledPointerWidth,
          center.y - radius - scaledPointerHeight + offset,
          center.x + scaledPointerWidth,
          center.y - radius + offset,
        );
        break;

      case PointerPosition.bottom:
        final tip = Offset(center.x, center.y + radius - offset);
        final left = Offset(
          center.x - scaledPointerWidth,
          center.y + radius + scaledPointerHeight - offset,
        );
        final right = Offset(
          center.x + scaledPointerWidth,
          center.y + radius + scaledPointerHeight - offset,
        );

        if (scaledBorderRadius > 0) {
          _addRoundedTriangle(
            pointerPath,
            tip,
            left,
            right,
            scaledBorderRadius,
          );
        } else {
          pointerPath
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
        }

        pointerBounds = Rect.fromLTRB(
          center.x - scaledPointerWidth,
          center.y + radius - offset,
          center.x + scaledPointerWidth,
          center.y + radius + scaledPointerHeight - offset,
        );
        break;

      case PointerPosition.left:
        final tip = Offset(center.x - radius + offset, center.y);
        final top = Offset(
          center.x - radius - scaledPointerHeight + offset,
          center.y - scaledPointerWidth,
        );
        final bottom = Offset(
          center.x - radius - scaledPointerHeight + offset,
          center.y + scaledPointerWidth,
        );

        if (scaledBorderRadius > 0) {
          _addRoundedTriangle(
            pointerPath,
            tip,
            top,
            bottom,
            scaledBorderRadius,
          );
        } else {
          pointerPath
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(top.dx, top.dy)
            ..lineTo(bottom.dx, bottom.dy)
            ..close();
        }

        pointerBounds = Rect.fromLTRB(
          center.x - radius - scaledPointerHeight + offset,
          center.y - scaledPointerWidth,
          center.x - radius + offset,
          center.y + scaledPointerWidth,
        );
        break;

      case PointerPosition.right:
        final tip = Offset(center.x + radius - offset, center.y);
        final top = Offset(
          center.x + radius + scaledPointerHeight - offset,
          center.y - scaledPointerWidth,
        );
        final bottom = Offset(
          center.x + radius + scaledPointerHeight - offset,
          center.y + scaledPointerWidth,
        );

        if (scaledBorderRadius > 0) {
          _addRoundedTriangle(
            pointerPath,
            tip,
            top,
            bottom,
            scaledBorderRadius,
          );
        } else {
          pointerPath
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(top.dx, top.dy)
            ..lineTo(bottom.dx, bottom.dy)
            ..close();
        }

        pointerBounds = Rect.fromLTRB(
          center.x + radius - offset,
          center.y - scaledPointerWidth,
          center.x + radius + scaledPointerHeight - offset,
          center.y + scaledPointerWidth,
        );
        break;
    }

    // Рисуем тени указателя (если заданы)
    if (pointerTheme.shadows != null && pointerTheme.shadows!.isNotEmpty) {
      for (final shadow in pointerTheme.shadows!) {
        final shadowPaint = Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

        canvas.save();
        canvas.translate(shadow.offset.dx, shadow.offset.dy);
        canvas.drawPath(pointerPath, shadowPaint);
        canvas.restore();
      }
    }

    // Рисуем указатель (с градиентом или цветом)
    final pointerPaint = Paint()..style = PaintingStyle.fill;

    if (pointerTheme.gradient != null) {
      pointerPaint.shader = pointerTheme.gradient!.createShader(pointerBounds);
    } else {
      pointerPaint.color = pointerTheme.color;
    }

    canvas.drawPath(pointerPath, pointerPaint);

    // Бордер указателя (рисуем только если borderWidth > 0)
    if (pointerTheme.borderWidth > 0) {
      final pointerBorderPaint = Paint()
        ..color = pointerTheme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = pointerTheme.borderWidth * scale;

      canvas.drawPath(pointerPath, pointerBorderPaint);
    }
  }

  void _drawCenterCircle(Canvas canvas, Vector2 center, double scale) {
    final centerTheme = theme.centerCircleTheme!;
    final scaledRadius = centerTheme.radius * scale;

    final centerPoint = Offset(center.x, center.y);

    // Рисуем тени центрального круга (если заданы)
    if (centerTheme.shadows != null && centerTheme.shadows!.isNotEmpty) {
      for (final shadow in centerTheme.shadows!) {
        final shadowPaint = Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

        canvas.drawCircle(
          centerPoint.translate(shadow.offset.dx, shadow.offset.dy),
          scaledRadius,
          shadowPaint,
        );
      }
    }

    // Рисуем центральный круг (с градиентом или цветом)
    final circlePaint = Paint()..style = PaintingStyle.fill;

    if (centerTheme.gradient != null) {
      circlePaint.shader = centerTheme.gradient!.createShader(
        Rect.fromCircle(center: centerPoint, radius: scaledRadius),
      );
    } else {
      circlePaint.color = centerTheme.color;
    }

    canvas.drawCircle(centerPoint, scaledRadius, circlePaint);

    // Бордер центрального круга (рисуем только если borderWidth > 0)
    if (centerTheme.borderWidth > 0) {
      final borderPaint = Paint()
        ..color = centerTheme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = centerTheme.borderWidth * scale;

      canvas.drawCircle(centerPoint, scaledRadius, borderPaint);
    }
  }

  // DEPRECATED: Не используется - оставлена для совместимости
  Path _DEPRECATED_OLD_createRoundedSectionPath(
    Vector2 center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
  ) {
    final path = Path();
    final endAngle = startAngle + sweepAngle;

    // Начинаем от внутреннего радиуса
    if (innerRadius > 0) {
      // Точки на внутреннем радиусе
      final innerStartX = center.x + innerRadius * math.cos(startAngle);
      final innerStartY = center.y + innerRadius * math.sin(startAngle);

      path.moveTo(innerStartX, innerStartY);

      // Линия к внешнему радиусу
      final outerStartX = center.x + outerRadius * math.cos(startAngle);
      final outerStartY = center.y + outerRadius * math.sin(startAngle);
      path.lineTo(outerStartX, outerStartY);

      // Дуга по внешнему радиусу
      path.arcTo(
        Rect.fromCircle(
          center: Offset(center.x, center.y),
          radius: outerRadius,
        ),
        startAngle,
        sweepAngle,
        false,
      );

      // Линия обратно к внутреннему радиусу
      final innerEndX = center.x + innerRadius * math.cos(endAngle);
      final innerEndY = center.y + innerRadius * math.sin(endAngle);
      path.lineTo(innerEndX, innerEndY);

      // Дуга по внутреннему радиусу (обратно)
      path.arcTo(
        Rect.fromCircle(
          center: Offset(center.x, center.y),
          radius: innerRadius,
        ),
        endAngle,
        -sweepAngle,
        false,
      );
    } else {
      // Обычная секция от центра (когда innerRadius = 0)
      path.moveTo(center.x, center.y);
      path.arcTo(
        Rect.fromCircle(
          center: Offset(center.x, center.y),
          radius: outerRadius,
        ),
        startAngle,
        sweepAngle,
        false,
      );
    }

    path.close();
    return path;
  }

  // DEPRECATED: Старая версия - не используется
  Path _DEPRECATED_createRoundedAnnulusSectionPath(
    Vector2 center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    double cornerRadius,
  ) {
    // Если нет внутреннего радиуса, используем старую функцию
    if (innerRadius <= 0) {
      return _createRoundedSectionPath(
        center,
        outerRadius,
        startAngle,
        sweepAngle,
        cornerRadius,
      );
    }

    final path = Path();
    final endAngle = startAngle + sweepAngle;

    // Ограничиваем радиус скругления
    final maxCornerRadius = math.min(
      (outerRadius - innerRadius) * 0.4,
      outerRadius * 0.2,
    );
    final cornerRadiusClamped = math.min(cornerRadius, maxCornerRadius);

    // Точки на внутреннем радиусе с отступом для скругления
    final innerStartX =
        center.x + (innerRadius + cornerRadiusClamped) * math.cos(startAngle);
    final innerStartY =
        center.y + (innerRadius + cornerRadiusClamped) * math.sin(startAngle);
    final innerEndX =
        center.x + (innerRadius + cornerRadiusClamped) * math.cos(endAngle);
    final innerEndY =
        center.y + (innerRadius + cornerRadiusClamped) * math.sin(endAngle);

    // Точки на внешнем радиусе с отступом для скругления
    final outerStartInnerX =
        center.x + (outerRadius - cornerRadiusClamped) * math.cos(startAngle);
    final outerStartInnerY =
        center.y + (outerRadius - cornerRadiusClamped) * math.sin(startAngle);
    final outerEndInnerX =
        center.x + (outerRadius - cornerRadiusClamped) * math.cos(endAngle);
    final outerEndInnerY =
        center.y + (outerRadius - cornerRadiusClamped) * math.sin(endAngle);

    // Угловые точки (сами углы без отступа)
    final outerStartX = center.x + outerRadius * math.cos(startAngle);
    final outerStartY = center.y + outerRadius * math.sin(startAngle);
    final outerEndX = center.x + outerRadius * math.cos(endAngle);
    final outerEndY = center.y + outerRadius * math.sin(endAngle);

    final innerCornerStartX = center.x + innerRadius * math.cos(startAngle);
    final innerCornerStartY = center.y + innerRadius * math.sin(startAngle);
    final innerCornerEndX = center.x + innerRadius * math.cos(endAngle);
    final innerCornerEndY = center.y + innerRadius * math.sin(endAngle);

    // Точки на дугах с угловым отступом
    final arcInset = cornerRadiusClamped / outerRadius;
    final innerArcInset = cornerRadiusClamped / innerRadius;

    final outerArcStartAngle = startAngle + arcInset;
    final outerArcEndAngle = endAngle - arcInset;
    final outerArcSweep = outerArcEndAngle - outerArcStartAngle;

    final innerArcStartAngle = startAngle + innerArcInset;
    final innerArcEndAngle = endAngle - innerArcInset;
    final innerArcSweep = innerArcEndAngle - innerArcStartAngle;

    final outerArcStartX =
        center.x + outerRadius * math.cos(outerArcStartAngle);
    final outerArcStartY =
        center.y + outerRadius * math.sin(outerArcStartAngle);

    final innerArcEndX = center.x + innerRadius * math.cos(innerArcEndAngle);
    final innerArcEndY = center.y + innerRadius * math.sin(innerArcEndAngle);

    // Строим путь со всеми скругленными углами
    path.moveTo(innerStartX, innerStartY);

    // Линия вдоль первой радиальной линии
    path.lineTo(outerStartInnerX, outerStartInnerY);

    // Скругленный угол 1 (внешний начало)
    path.quadraticBezierTo(
      outerStartX,
      outerStartY,
      outerArcStartX,
      outerArcStartY,
    );

    // Дуга по внешнему краю
    if (outerArcSweep > 0) {
      path.arcTo(
        Rect.fromCircle(
          center: Offset(center.x, center.y),
          radius: outerRadius,
        ),
        outerArcStartAngle,
        outerArcSweep,
        false,
      );
    }

    // Скругленный угол 2 (внешний конец)
    path.quadraticBezierTo(
      outerEndX,
      outerEndY,
      outerEndInnerX,
      outerEndInnerY,
    );

    // Линия вдоль второй радиальной линии
    path.lineTo(innerEndX, innerEndY);

    // Скругленный угол 3 (внутренний конец)
    path.quadraticBezierTo(
      innerCornerEndX,
      innerCornerEndY,
      innerArcEndX,
      innerArcEndY,
    );

    // Дуга по внутреннему краю (обратно)
    if (innerArcSweep > 0) {
      path.arcTo(
        Rect.fromCircle(
          center: Offset(center.x, center.y),
          radius: innerRadius,
        ),
        innerArcEndAngle,
        -innerArcSweep,
        false,
      );
    }

    // Скругленный угол 4 (внутренний начало)
    path.quadraticBezierTo(
      innerCornerStartX,
      innerCornerStartY,
      innerStartX,
      innerStartY,
    );

    path.close();
    return path;
  }

  // Создает секцию со всеми скругленными углами от центра
  Path _createRoundedSectionPath(
    Vector2 center,
    double radius,
    double startAngle,
    double sweepAngle,
    double cornerRadius,
  ) {
    final path = Path();
    final endAngle = startAngle + sweepAngle;

    // Ограничиваем радиус скругления
    final cornerRadiusClamped = math.min(cornerRadius, radius * 0.3);

    // ========== Точки для внутреннего угла (у центра) ==========
    final innerStartX = center.x + cornerRadiusClamped * math.cos(startAngle);
    final innerStartY = center.y + cornerRadiusClamped * math.sin(startAngle);
    final innerEndX = center.x + cornerRadiusClamped * math.cos(endAngle);
    final innerEndY = center.y + cornerRadiusClamped * math.sin(endAngle);

    // ========== Точки для внешних углов ==========
    // Отступаем на cornerRadius от внешних углов вдоль радиальных линий
    final outerStartInnerX =
        center.x + (radius - cornerRadiusClamped) * math.cos(startAngle);
    final outerStartInnerY =
        center.y + (radius - cornerRadiusClamped) * math.sin(startAngle);
    final outerEndInnerX =
        center.x + (radius - cornerRadiusClamped) * math.cos(endAngle);
    final outerEndInnerY =
        center.y + (radius - cornerRadiusClamped) * math.sin(endAngle);

    // Точки на внешнем крае (сами углы)
    final outerStartX = center.x + radius * math.cos(startAngle);
    final outerStartY = center.y + radius * math.sin(startAngle);
    final outerEndX = center.x + radius * math.cos(endAngle);
    final outerEndY = center.y + radius * math.sin(endAngle);

    // Точки на дуге с отступом для скругления
    final arcInset = cornerRadiusClamped / radius; // Угловой отступ
    final arcStartAngle = startAngle + arcInset;
    final arcEndAngle = endAngle - arcInset;
    final arcSweep = arcEndAngle - arcStartAngle;

    final arcStartX = center.x + radius * math.cos(arcStartAngle);
    final arcStartY = center.y + radius * math.sin(arcStartAngle);

    // ========== Строим путь со всеми скругленными углами ==========

    // Начинаем от внутренней точки на первой радиальной линии
    path.moveTo(innerStartX, innerStartY);

    // Линия вдоль первой радиальной линии к внешнему краю
    path.lineTo(outerStartInnerX, outerStartInnerY);

    // Скругленный угол 1 (первый внешний угол)
    path.quadraticBezierTo(outerStartX, outerStartY, arcStartX, arcStartY);

    // Дуга по внешнему краю (если есть место)
    if (arcSweep > 0) {
      path.arcTo(
        Rect.fromCircle(center: Offset(center.x, center.y), radius: radius),
        arcStartAngle,
        arcSweep,
        false,
      );
    }

    // Скругленный угол 2 (второй внешний угол)
    path.quadraticBezierTo(
      outerEndX,
      outerEndY,
      outerEndInnerX,
      outerEndInnerY,
    );

    // Линия вдоль второй радиальной линии обратно к центру
    path.lineTo(innerEndX, innerEndY);

    // Скругленный угол 3 (угол у центра)
    path.quadraticBezierTo(center.x, center.y, innerStartX, innerStartY);

    path.close();
    return path;
  }

  // Создает треугольник с закругленными углами
  void _addRoundedTriangle(
    Path path,
    Offset p1,
    Offset p2,
    Offset p3,
    double radius,
  ) {
    // Вычисляем векторы от каждой вершины к соседним
    final v1to2 = Offset(p2.dx - p1.dx, p2.dy - p1.dy);
    final v1to3 = Offset(p3.dx - p1.dx, p3.dy - p1.dy);
    final v2to1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final v2to3 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);
    final v3to1 = Offset(p1.dx - p3.dx, p1.dy - p3.dy);
    final v3to2 = Offset(p2.dx - p3.dx, p2.dy - p3.dy);

    // Нормализуем векторы
    final len1to2 = math.sqrt(v1to2.dx * v1to2.dx + v1to2.dy * v1to2.dy);
    final len1to3 = math.sqrt(v1to3.dx * v1to3.dx + v1to3.dy * v1to3.dy);
    final len2to3 = math.sqrt(v2to3.dx * v2to3.dx + v2to3.dy * v2to3.dy);

    final n1to2 = Offset(v1to2.dx / len1to2, v1to2.dy / len1to2);
    final n1to3 = Offset(v1to3.dx / len1to3, v1to3.dy / len1to3);
    final n2to1 = Offset(v2to1.dx / len1to2, v2to1.dy / len1to2);
    final n2to3 = Offset(v2to3.dx / len2to3, v2to3.dy / len2to3);
    final n3to1 = Offset(v3to1.dx / len1to3, v3to1.dy / len1to3);
    final n3to2 = Offset(v3to2.dx / len2to3, v3to2.dy / len2to3);

    // Точки для скругления на каждой стороне
    final start1 = Offset(p1.dx + n1to2.dx * radius, p1.dy + n1to2.dy * radius);
    final end1 = Offset(p2.dx + n2to1.dx * radius, p2.dy + n2to1.dy * radius);

    final start2 = Offset(p2.dx + n2to3.dx * radius, p2.dy + n2to3.dy * radius);
    final end2 = Offset(p3.dx + n3to2.dx * radius, p3.dy + n3to2.dy * radius);

    final start3 = Offset(p3.dx + n3to1.dx * radius, p3.dy + n3to1.dy * radius);
    final end3 = Offset(p1.dx + n1to3.dx * radius, p1.dy + n1to3.dy * radius);

    // Строим путь с квадратичными кривыми Безье в углах
    path.moveTo(start1.dx, start1.dy);
    path.lineTo(end1.dx, end1.dy);
    path.quadraticBezierTo(p2.dx, p2.dy, start2.dx, start2.dy);
    path.lineTo(end2.dx, end2.dy);
    path.quadraticBezierTo(p3.dx, p3.dy, start3.dx, start3.dy);
    path.lineTo(end3.dx, end3.dy);
    path.quadraticBezierTo(p1.dx, p1.dy, start1.dx, start1.dy);
    path.close();
  }
}

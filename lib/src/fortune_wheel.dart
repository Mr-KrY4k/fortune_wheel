import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'wheel_section.dart';

class FortuneWheelGame extends FlameGame with TapDetector {
  late FortuneWheel wheel;
  Function(SectionType)? onResult;
  final double spinDuration;
  final Color bgColor;
  final PointerPosition pointerPosition;
  final double pointerOffset;
  final double pointerWidth;
  final double pointerHeight;
  final int sectionsCount;
  final bool showSectionIndex;

  FortuneWheelGame({
    this.onResult,
    this.spinDuration = 3.0,
    this.bgColor = const Color(0xFF000000),
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.pointerWidth = 25.0,
    this.pointerHeight = 40.0,
    this.sectionsCount = 10,
    this.showSectionIndex = false,
  });

  @override
  Color backgroundColor() => bgColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    wheel = FortuneWheel(
      sections: _createSections(),
      spinDuration: spinDuration,
      pointerPosition: pointerPosition,
      pointerOffset: pointerOffset,
      pointerWidth: pointerWidth,
      pointerHeight: pointerHeight,
      showSectionIndex: showSectionIndex,
      onSpinComplete: (result) {
        onResult?.call(result);
      },
    );

    add(wheel);
  }

  List<WheelSection> _createSections() {
    return List.generate(sectionsCount, (index) {
      final isWin = index.isEven;
      return WheelSection(
        type: isWin ? SectionType.win : SectionType.lose,
        color: isWin ? Colors.green : Colors.red,
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
  final double pointerWidth;
  final double pointerHeight;
  final bool showSectionIndex;

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
    this.pointerWidth = 25.0,
    this.pointerHeight = 40.0,
    this.showSectionIndex = false,
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

      final path = Path()
        ..moveTo(center.x, center.y)
        ..arcTo(
          Rect.fromCircle(center: Offset(center.x, center.y), radius: radius),
          startAngle,
          sectionAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, 2 * scale);

      canvas.drawPath(path, borderPaint);

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

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, 4 * scale);

    canvas.drawCircle(Offset(center.x, center.y), radius, borderPaint);

    _drawPointer(canvas, center, radius, scale);
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

    final fontSize = math.max(8.0, 16 * scale);

    if (showIndex) {
      final indexFontSize = math.max(12.0, 20 * scale);
      final indexPainter = TextPainter(
        text: TextSpan(
          text: '$index',
          style: TextStyle(
            color: Colors.white,
            fontSize: indexFontSize,
            fontWeight: FontWeight.bold,
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
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
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
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
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
    final pointerPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    final scaledPointerWidth = math.max(8, pointerWidth * scale);
    final scaledPointerHeight = math.max(10, pointerHeight * scale);
    final offset = pointerOffset * scale;

    final pointerPath = Path();

    switch (pointerPosition) {
      case PointerPosition.top:
        pointerPath
          ..moveTo(center.x, center.y - radius + offset)
          ..lineTo(
            center.x - scaledPointerWidth,
            center.y - radius - scaledPointerHeight + offset,
          )
          ..lineTo(
            center.x + scaledPointerWidth,
            center.y - radius - scaledPointerHeight + offset,
          )
          ..close();
        break;
      case PointerPosition.bottom:
        pointerPath
          ..moveTo(center.x, center.y + radius - offset)
          ..lineTo(
            center.x - scaledPointerWidth,
            center.y + radius + scaledPointerHeight - offset,
          )
          ..lineTo(
            center.x + scaledPointerWidth,
            center.y + radius + scaledPointerHeight - offset,
          )
          ..close();
        break;
      case PointerPosition.left:
        pointerPath
          ..moveTo(center.x - radius + offset, center.y)
          ..lineTo(
            center.x - radius - scaledPointerHeight + offset,
            center.y - scaledPointerWidth,
          )
          ..lineTo(
            center.x - radius - scaledPointerHeight + offset,
            center.y + scaledPointerWidth,
          )
          ..close();
        break;
      case PointerPosition.right:
        pointerPath
          ..moveTo(center.x + radius - offset, center.y)
          ..lineTo(
            center.x + radius + scaledPointerHeight - offset,
            center.y - scaledPointerWidth,
          )
          ..lineTo(
            center.x + radius + scaledPointerHeight - offset,
            center.y + scaledPointerWidth,
          )
          ..close();
        break;
    }

    canvas.drawPath(pointerPath, pointerPaint);

    final pointerBorderPaint = Paint()
      ..color = const Color(0xFFBD8A31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, 2 * scale);

    canvas.drawPath(pointerPath, pointerBorderPaint);
  }
}

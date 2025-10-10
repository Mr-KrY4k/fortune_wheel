import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'fortune_wheel_theme.dart';
import 'wheel_section.dart';

/// Этапы вращения колеса
enum SpinPhase {
  acceleration, // Разгон
  constantSpeed, // Постоянная скорость
  deceleration, // Замедление
}

class FortuneWheelGame extends FlameGame with TapDetector {
  late FortuneWheel wheel;
  Function(SectionType)? onResult;

  /// Время вращения с постоянной скоростью после завершения внешней функции
  final double spinDuration;

  final PointerPosition pointerPosition;
  final double pointerOffset;
  final int sectionsCount;
  final bool showSectionIndex;
  final FortuneWheelTheme theme;

  /// Время разгона в секундах (первый этап)
  final double accelerationDuration;

  /// Коэффициент/время замедления:
  /// - В режиме с целевой секцией: коэффициент расстояния (больше = больше оборотов до остановки)
  /// - В режиме без цели: время замедления в секундах
  /// Рекомендуемый диапазон: 0.5 - 3.0
  final double decelerationDuration;

  /// Скорость вращения от 0.0 (не включая) до 1.0 (быстро)
  /// Допустимые значения: 0.0 < speed <= 1.0
  final double speed;

  /// Callback который вызывается когда колесо достигает постоянной скорости
  /// Пока этот callback работает, колесо крутится
  Function()? onConstantSpeedReached;

  /// Минимальная скорость вращения в радианах/секунду (при speed = 0.0)
  static const double _minRotationSpeed = 5.0;

  /// Максимальная скорость вращения в радианах/секунду (при speed = 1.0)
  static const double _maxRotationSpeed = 25.0;

  FortuneWheelGame({
    this.onResult,
    this.spinDuration = 3.0,
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.sectionsCount = 10,
    this.showSectionIndex = false,
    this.theme = const FortuneWheelTheme(),
    this.accelerationDuration = 0.5,
    this.decelerationDuration = 2.0,
    this.speed = 0.7,
  }) : assert(
         speed > 0.0 && speed <= 1.0,
         'Speed must be between 0.0 (exclusive) and 1.0',
       );

  @override
  Color backgroundColor() => theme.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Конвертируем нормализованную скорость (0.0-1.0) в радианы/секунду
    final maxRotationSpeed =
        _minRotationSpeed + (speed * (_maxRotationSpeed - _minRotationSpeed));

    wheel = FortuneWheel(
      sections: _createSections(),
      spinDuration: spinDuration,
      pointerPosition: pointerPosition,
      pointerOffset: pointerOffset,
      showSectionIndex: showSectionIndex,
      theme: theme,
      accelerationDuration: accelerationDuration,
      decelerationDuration: decelerationDuration,
      maxRotationSpeed: maxRotationSpeed,
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

  /// Сигнализирует что внешняя функция завершилась и можно начинать финальный этап
  void notifyExternalFunctionComplete() {
    wheel.notifyExternalFunctionComplete();
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
  final double accelerationDuration;
  final double decelerationDuration;
  final double maxRotationSpeed;

  double currentRotation = 0;
  double rotationSpeed = 0;
  bool isSpinning = false;
  int? resultIndex;
  double elapsedTime = 0;
  double? targetRotation;
  int? targetSectionIndex;
  double currentSpinDuration = 3.0;
  double startRotation = 0;

  // Отладка: отслеживание резких изменений
  double _lastRotation = 0;
  double _lastSpeed = 0;

  /// Текущий этап вращения
  SpinPhase currentPhase = SpinPhase.acceleration;

  /// Время начала этапа постоянной скорости
  double constantSpeedStartTime = 0;

  /// Время начала этапа замедления
  double decelerationStartTime = 0;

  /// Угол поворота в начале замедления (для интерполяции)
  double rotationAtDecelerationStart = 0;

  /// Скорость в начале замедления (рассчитывается динамически)
  double decelerationStartSpeed = 0;

  /// Фактическое время замедления (рассчитывается автоматически)
  double actualDecelerationDuration = 0;

  /// Ожидаем ли завершения внешней функции
  bool waitingForExternalFunction = false;

  /// Время когда внешняя функция завершилась и начался финальный этап
  double? finalSpinStartTime;

  /// Вызывался ли callback onConstantSpeedReached
  bool constantSpeedCallbackCalled = false;

  // ========== Кэшированные константы ==========

  /// Константа 2π (для избежания повторных вычислений)
  static const double _twoPi = 2 * math.pi;

  /// Угол одной секции (кэшируется при загрузке)
  late final double _sectionAngle;

  /// Угол указателя (кэшируется при загрузке)
  late final double _pointerAngle;

  /// Нормализованный угол указателя [0, 2π)
  late final double _normalizedPointerAngle;

  /// Естественное расстояние замедления (для режима с целью)
  late final double _naturalDistance;

  // ================================================

  /// Кэшированные Path для секций (для производительности)
  List<Path>? cachedSectionPaths;

  /// Последний scale для которого были созданы Path
  double? lastScale;

  /// Кэшированные Paint объекты
  final List<Paint> _fillPaints = [];
  Paint? _sectionBorderPaint;
  Paint? _wheelBorderPaint;

  FortuneWheel({
    required this.sections,
    required this.onSpinComplete,
    this.spinDuration = 3.0,
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.showSectionIndex = false,
    this.theme = const FortuneWheelTheme(),
    required this.accelerationDuration,
    required this.decelerationDuration,
    required this.maxRotationSpeed,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final availableSize = math.min(game.size.x, game.size.y) - 50;
    size = Vector2.all(availableSize);
    position = game.size / 2;
    anchor = Anchor.center;

    // Кэшируем константные значения для оптимизации
    _sectionAngle = _twoPi / sections.length;
    _pointerAngle = _getPointerAngleByPosition(pointerPosition);
    _normalizedPointerAngle = _normalizeAngle(_pointerAngle);
    _naturalDistance = maxRotationSpeed * decelerationDuration;
  }

  /// Возвращает угол указателя в зависимости от позиции
  double _getPointerAngleByPosition(PointerPosition position) {
    switch (position) {
      case PointerPosition.top:
        return -math.pi / 2;
      case PointerPosition.bottom:
        return math.pi / 2;
      case PointerPosition.left:
        return math.pi;
      case PointerPosition.right:
        return 0;
    }
  }

  /// Нормализует угол к диапазону [0, 2π)
  double _normalizeAngle(double angle) {
    var normalized = angle % _twoPi;
    if (normalized < 0) normalized += _twoPi;
    return normalized;
  }

  void spin({int? targetSection, double? duration}) {
    if (isSpinning) return;

    print('🎲 НАЧАЛО ВРАЩЕНИЯ:');
    print('   Целевая секция: ${targetSection ?? "случайная"}');
    print('   Длительность: ${duration ?? spinDuration}s');
    print('   Начальная позиция: ${currentRotation.toStringAsFixed(3)} рад');
    print('   Max скорость: ${maxRotationSpeed.toStringAsFixed(3)} рад/с');

    isSpinning = true;
    elapsedTime = 0;
    resultIndex = null;
    targetSectionIndex = targetSection;
    startRotation = currentRotation;

    // Начинаем с этапа разгона
    currentPhase = SpinPhase.acceleration;
    rotationSpeed = 0; // Начинаем с нулевой скорости

    currentSpinDuration = duration ?? spinDuration;

    // Сбрасываем флаги
    waitingForExternalFunction =
        targetSection != null; // Ждем только если есть цель
    finalSpinStartTime = null;
    constantSpeedCallbackCalled = false;
    actualDecelerationDuration =
        decelerationDuration; // Инициализируем по умолчанию

    // Сбрасываем отладочные переменные
    _lastRotation = currentRotation;
    _lastSpeed = 0;

    if (targetSectionIndex != null) {
      // Рассчитываем целевой угол для остановки на конкретной секции
      _calculateTargetRotationForSection();
    } else {
      // Случайное вращение - просто крутимся с заданной скоростью
      targetRotation = null;
    }
  }

  /// Вызывается когда внешняя функция завершилась
  void notifyExternalFunctionComplete() {
    if (waitingForExternalFunction && finalSpinStartTime == null) {
      finalSpinStartTime = elapsedTime;
      print('✅ ВНЕШНЯЯ ФУНКЦИЯ ЗАВЕРШЕНА:');
      print('   Время: ${elapsedTime.toStringAsFixed(3)}s');
      print('   Начало финального вращения на ${currentSpinDuration}s');
    }
  }

  /// Начинает замедление к целевой секции от текущей позиции
  void _startDecelerationToTarget() {
    // Пересчитываем целевой угол от текущей позиции
    var targetSectionCenter =
        targetSectionIndex! * _sectionAngle - math.pi / 2 + _sectionAngle / 2;
    targetSectionCenter = _normalizeAngle(targetSectionCenter);

    var baseRotation = _normalizedPointerAngle - targetSectionCenter;

    // Добавляем случайное отклонение
    final randomOffset =
        (math.Random().nextDouble() - 0.5) * _sectionAngle * 0.6;
    baseRotation += randomOffset;

    baseRotation = _normalizeAngle(baseRotation);

    // Находим угол целевой секции в следующем обороте
    while (baseRotation <= currentRotation) {
      baseRotation += _twoPi;
    }

    // ШАГ 1: Используем кэшированное естественное расстояние замедления
    // ШАГ 2: Сколько полных оборотов естественно получится
    final naturalFullRotations = (_naturalDistance / _twoPi).floor();

    // ШАГ 3: Находим все возможные остановки на целевой секции в диапазоне ±2 оборота от естественного
    final minRotations = math.max(1, naturalFullRotations - 2);
    final maxRotations = naturalFullRotations + 2;

    // Расстояние до секции в первом обороте
    final distanceToFirstOccurrence = baseRotation - currentRotation;

    // Пробуем разные количества оборотов и выбираем ближайшее к естественному
    double? bestDistance;
    int bestRotations = minRotations;
    double minSpeedDifference = double.infinity;

    for (int rotations = minRotations; rotations <= maxRotations; rotations++) {
      final testDistance = (rotations - 1) * _twoPi + distanceToFirstOccurrence;
      final distanceDifference = (testDistance - _naturalDistance).abs();

      // Выбираем расстояние ближайшее к естественному
      if (distanceDifference < minSpeedDifference) {
        minSpeedDifference = distanceDifference;
        bestDistance = testDistance;
        bestRotations = rotations;
      }
    }

    // Если не нашли подходящий вариант (все превышают скорость), берем минимум
    if (bestDistance == null) {
      bestRotations = minRotations;
      bestDistance = (bestRotations - 1) * _twoPi + distanceToFirstOccurrence;
    }

    targetRotation = currentRotation + bestDistance;

    // Переходим к замедлению
    currentPhase = SpinPhase.deceleration;
    decelerationStartTime = elapsedTime;
    rotationAtDecelerationStart = currentRotation;

    // Рассчитываем время замедления
    // Для easeOutQuad: средняя скорость = 50% от максимальной
    // distance = avgSpeed × time, откуда: time = distance / (0.5 × maxSpeed)
    decelerationStartSpeed = maxRotationSpeed; // Начинаем с текущей скорости!
    actualDecelerationDuration = bestDistance / (0.5 * maxRotationSpeed);

    print('🎯 ПАРАМЕТРЫ ЗАМЕДЛЕНИЯ:');
    print('   Текущая позиция: ${currentRotation.toStringAsFixed(3)} рад');
    print('   Целевая позиция: ${targetRotation!.toStringAsFixed(3)} рад');
    print(
      '   Расстояние: ${bestDistance.toStringAsFixed(3)} рад (${(bestDistance / _twoPi).toStringAsFixed(2)} оборотов)',
    );
    print(
      '   Начальная скорость: ${decelerationStartSpeed.toStringAsFixed(3)} рад/с',
    );
    print(
      '   Время замедления: ${actualDecelerationDuration.toStringAsFixed(3)}s',
    );
  }

  /// Рассчитывает целевой угол поворота для остановки на конкретной секции
  void _calculateTargetRotationForSection() {
    // Центр целевой секции (в системе координат колеса без поворота)
    var targetSectionCenter =
        targetSectionIndex! * _sectionAngle - math.pi / 2 + _sectionAngle / 2;
    targetSectionCenter = _normalizeAngle(targetSectionCenter);

    // Целевой угол поворота для попадания в секцию
    var baseRotation = _normalizedPointerAngle - targetSectionCenter;

    // Добавляем небольшое случайное отклонение от центра секции (±30% от половины секции)
    final randomOffset =
        (math.Random().nextDouble() - 0.5) * _sectionAngle * 0.6;
    baseRotation += randomOffset;

    // Нормализуем baseRotation к [0, 2π)
    baseRotation = _normalizeAngle(baseRotation);

    // Добавляем минимум 3 полных оборота
    final extraRotations = (3 + math.Random().nextInt(3)).toDouble();

    // Находим ближайший угол больше текущего
    while (baseRotation <= currentRotation) {
      baseRotation += _twoPi;
    }

    targetRotation = baseRotation + extraRotations * _twoPi;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isSpinning) {
      elapsedTime += dt;

      if (targetRotation != null) {
        // Режим с целевой секцией - используем точное управление углом
        _updateWithTargetRotation(dt);
      } else {
        // Режим без цели - просто крутимся по времени
        _updateWithoutTarget(dt);
      }

      // Отладка: отслеживаем резкие изменения
      _checkForJumps(dt);
    }
  }

  /// Отладочный метод для отслеживания резких изменений
  void _checkForJumps(double dt) {
    if (dt > 0) {
      final rotationDelta = (currentRotation - _lastRotation).abs();
      final speedDelta = (rotationSpeed - _lastSpeed).abs();

      // Ожидаемое изменение позиции за dt
      final expectedDelta = _lastSpeed * dt;
      final positionJump = (rotationDelta - expectedDelta).abs();

      // Очень чувствительное обнаружение
      const speedJumpThreshold = 0.1; // рад/с (было 0.5)
      const positionJumpThreshold = 0.05; // радианы (было 0.1)

      if (speedDelta > speedJumpThreshold) {
        print('⚠️ РЕЗКОЕ ИЗМЕНЕНИЕ СКОРОСТИ:');
        print('  Фаза: $currentPhase');
        print('  Время: ${elapsedTime.toStringAsFixed(3)}s');
        print('  dt: ${dt.toStringAsFixed(4)}s');
        print('  Была: ${_lastSpeed.toStringAsFixed(3)} рад/с');
        print('  Стала: ${rotationSpeed.toStringAsFixed(3)} рад/с');
        print('  Δ = ${speedDelta.toStringAsFixed(3)} рад/с');
      }

      if (positionJump > positionJumpThreshold) {
        print('⚠️ РЕЗКИЙ СКАЧОК ПОЗИЦИИ:');
        print('  Фаза: $currentPhase');
        print('  Время: ${elapsedTime.toStringAsFixed(3)}s');
        print('  dt: ${dt.toStringAsFixed(4)}s');
        print('  Позиция: ${currentRotation.toStringAsFixed(3)} рад');
        print('  Была: ${_lastRotation.toStringAsFixed(3)} рад');
        print('  Изменение: ${rotationDelta.toStringAsFixed(3)} рад');
        print('  Ожидалось: ${expectedDelta.toStringAsFixed(3)} рад');
        print('  Скачок: ${positionJump.toStringAsFixed(3)} рад');
      }
    }

    _lastRotation = currentRotation;
    _lastSpeed = rotationSpeed;
  }

  /// Обновление с точным попаданием в целевую секцию
  void _updateWithTargetRotation(double dt) {
    // ЭТАП 1: РАЗГОН до заданной скорости
    if (currentPhase == SpinPhase.acceleration) {
      final accelerationProgress = math.min(
        elapsedTime / accelerationDuration,
        1.0,
      );
      // Линейное изменение скорости = постоянное ускорение (плавно!)
      rotationSpeed = math.min(
        maxRotationSpeed * accelerationProgress,
        maxRotationSpeed,
      );
      currentRotation += rotationSpeed * dt;

      // Убрал частое логирование для производительности

      // Проверяем завершение разгона
      if (accelerationProgress >= 1.0) {
        print('🔄 ПЕРЕХОД: Acceleration → ConstantSpeed');
        print('   Время: ${elapsedTime.toStringAsFixed(3)}s');
        print('   Скорость: ${rotationSpeed.toStringAsFixed(3)} рад/с');

        currentPhase = SpinPhase.constantSpeed;

        // Вызываем callback если есть
        if (game.onConstantSpeedReached != null &&
            !constantSpeedCallbackCalled) {
          constantSpeedCallbackCalled = true;
          game.onConstantSpeedReached!();
        }
      }
    }
    // ЭТАП 2: ПОСТОЯННАЯ СКОРОСТЬ
    else if (currentPhase == SpinPhase.constantSpeed) {
      // Крутим с постоянной скоростью
      rotationSpeed = maxRotationSpeed;
      currentRotation += rotationSpeed * dt;

      // Проверяем статус внешней функции
      if (finalSpinStartTime == null) {
        // Ждем завершения внешней функции - просто крутимся
        // (убрано частое логирование для производительности)
      } else {
        // Внешняя функция завершилась - крутим еще spinDuration
        final finalSpinElapsed = elapsedTime - finalSpinStartTime!;

        // Проверяем, истекло ли время финальной прокрутки
        if (finalSpinElapsed >= currentSpinDuration) {
          print('🔄 ПЕРЕХОД: ConstantSpeed → начало замедления');
          print('   Время: ${elapsedTime.toStringAsFixed(3)}s');
          print(
            '   Текущая скорость: ${rotationSpeed.toStringAsFixed(3)} рад/с',
          );
          print(
            '   Текущая позиция: ${currentRotation.toStringAsFixed(3)} рад',
          );

          // Автоматически начинаем замедление к целевой секции
          if (targetSectionIndex != null) {
            _startDecelerationToTarget();
          } else {
            // Нет целевой секции - просто останавливаемся
            isSpinning = false;
            rotationSpeed = 0;
            _calculateResult();
          }
          return;
        }
      }
    }
    // ЭТАП 3: ЗАМЕДЛЕНИЕ
    else if (currentPhase == SpinPhase.deceleration) {
      final decelerationElapsed = elapsedTime - decelerationStartTime;
      final decelerationProgress = math.min(
        decelerationElapsed / actualDecelerationDuration,
        1.0,
      );

      if (decelerationProgress >= 1.0) {
        print('🏁 ОСТАНОВКА:');
        print('   Время: ${elapsedTime.toStringAsFixed(3)}s');
        print(
          '   Финальная позиция: ${targetRotation!.toStringAsFixed(3)} рад',
        );

        // Остановка - точно устанавливаем целевую позицию
        currentRotation = targetRotation!;
        isSpinning = false;
        rotationSpeed = 0;
        _calculateResult();
      } else {
        // Линейное снижение скорости = постоянное торможение (плавно!)
        rotationSpeed = decelerationStartSpeed * (1.0 - decelerationProgress);

        // Позиция вычисляется интегрированием линейной скорости
        // v(t) = v0(1-t) → s(t) = ∫v dt = v0*t - v0*t²/2
        // Нормализованная форма: s = t(2-t), что эквивалентно easeOutQuad
        // Производная: ds/dt = 2(1-t) ✓ согласуется со скоростью выше
        final totalDistance = targetRotation! - rotationAtDecelerationStart;
        currentRotation =
            rotationAtDecelerationStart +
            totalDistance * decelerationProgress * (2.0 - decelerationProgress);
      }
    }
  }

  /// Обновление без целевой секции (просто крутится)
  void _updateWithoutTarget(double dt) {
    // ЭТАП 1: РАЗГОН
    if (currentPhase == SpinPhase.acceleration) {
      final accelerationProgress = math.min(
        elapsedTime / accelerationDuration,
        1.0,
      );
      // Линейное изменение скорости = постоянное ускорение (плавно!)
      rotationSpeed = math.min(
        maxRotationSpeed * accelerationProgress,
        maxRotationSpeed,
      );
      currentRotation += rotationSpeed * dt;

      if (accelerationProgress >= 1.0) {
        currentPhase = SpinPhase.constantSpeed;
        constantSpeedStartTime = elapsedTime;
      }
    }
    // ЭТАП 2: ПОСТОЯННАЯ СКОРОСТЬ
    else if (currentPhase == SpinPhase.constantSpeed) {
      rotationSpeed = maxRotationSpeed;
      currentRotation += rotationSpeed * dt;

      final constantSpeedElapsed = elapsedTime - constantSpeedStartTime;
      if (constantSpeedElapsed >= currentSpinDuration) {
        currentPhase = SpinPhase.deceleration;
        decelerationStartTime = elapsedTime;
      }
    }
    // ЭТАП 3: ЗАМЕДЛЕНИЕ
    else if (currentPhase == SpinPhase.deceleration) {
      final decelerationElapsed = elapsedTime - decelerationStartTime;
      final decelerationProgress = math.min(
        decelerationElapsed / decelerationDuration,
        1.0,
      );

      // Используем ease-out для плавного перехода (как в CSS)
      // Линейно снижаем скорость для простоты в режиме без цели
      rotationSpeed = maxRotationSpeed * (1.0 - decelerationProgress);
      currentRotation += rotationSpeed * dt;

      if (decelerationProgress >= 1.0) {
        isSpinning = false;
        rotationSpeed = 0;
        _calculateResult();
      }
    }
  }

  void _calculateResult() {
    // Центр секции i после поворота: (i * sectionAngle - π/2 + sectionAngle/2) + currentRotation = pointerAngle
    // i * sectionAngle = pointerAngle - currentRotation + π/2 - sectionAngle/2
    // i = (pointerAngle - currentRotation + π/2 - sectionAngle/2) / sectionAngle

    var angleForCalc =
        _pointerAngle - currentRotation + math.pi / 2 - _sectionAngle / 2;

    // Нормализуем
    angleForCalc = _normalizeAngle(angleForCalc);

    var sectionFloat = angleForCalc / _sectionAngle;
    resultIndex = sectionFloat.round() % sections.length;

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

    // Кэшируем Path объекты для производительности
    if (cachedSectionPaths == null || lastScale != scale) {
      cachedSectionPaths = [];
      lastScale = scale;

      final scaledSectionRadius =
          theme.sectionsTheme.sectionBorderRadius * scale;

      for (int i = 0; i < sections.length; i++) {
        final startAngle = i * _sectionAngle - math.pi / 2;

        final Path path;
        if (scaledSectionRadius > 0) {
          path = _createRoundedSectionPath(
            center,
            radius,
            startAngle,
            _sectionAngle,
            scaledSectionRadius,
          );
        } else {
          path = Path()
            ..moveTo(center.x, center.y)
            ..arcTo(
              Rect.fromCircle(
                center: Offset(center.x, center.y),
                radius: radius,
              ),
              startAngle,
              _sectionAngle,
              false,
            )
            ..close();
        }

        cachedSectionPaths!.add(path);
      }

      // Кэшируем Paint объекты для секций
      _fillPaints.clear();
      for (int i = 0; i < sections.length; i++) {
        _fillPaints.add(
          Paint()
            ..color = sections[i].color
            ..style = PaintingStyle.fill,
        );
      }

      // Кэшируем Paint для бордеров
      if (theme.sectionsTheme.sectionBorderWidth > 0) {
        _sectionBorderPaint = Paint()
          ..color = theme.sectionsTheme.sectionBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = theme.sectionsTheme.sectionBorderWidth * scale;
      }

      if (theme.borderTheme.width > 0) {
        _wheelBorderPaint = Paint()
          ..color = theme.borderTheme.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = theme.borderTheme.width * scale;
      }
    }

    canvas.save();
    canvas.translate(center.x, center.y);
    canvas.rotate(currentRotation);
    canvas.translate(-center.x, -center.y);

    // Рисуем секции используя кэшированные объекты
    for (int i = 0; i < sections.length; i++) {
      final path = cachedSectionPaths![i];
      final paint = _fillPaints[i];

      canvas.drawPath(path, paint);

      // Бордер секции
      if (_sectionBorderPaint != null) {
        canvas.drawPath(path, _sectionBorderPaint!);
      }

      final startAngle = i * _sectionAngle - math.pi / 2;
      _drawText(
        canvas,
        sections[i].label,
        i,
        center,
        radius,
        startAngle + _sectionAngle / 2,
        scale,
        showSectionIndex,
      );
    }

    canvas.restore();

    // Бордер колеса
    if (_wheelBorderPaint != null) {
      canvas.drawCircle(Offset(center.x, center.y), radius, _wheelBorderPaint!);
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

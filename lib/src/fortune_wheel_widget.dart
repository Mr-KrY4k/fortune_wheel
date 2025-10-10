import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'fortune_wheel.dart';
import 'fortune_wheel_theme.dart';
import 'wheel_section.dart';

class FortuneWheelWidget extends StatefulWidget {
  final Function(SectionType)? onResult;
  final double? width;
  final double? height;

  /// Время вращения с постоянной скоростью после завершения внешней функции
  final double spinDuration;

  final PointerPosition pointerPosition;
  final double pointerOffset;
  final int sectionsCount;
  final bool showSectionIndex;

  /// Тема для колеса фортуны
  final FortuneWheelTheme theme;

  /// Время разгона в секундах (первый этап)
  final double accelerationDuration;

  /// Коэффициент/время замедления:
  /// - С целевой секцией: коэффициент расстояния (больше = больше оборотов)
  /// - Без цели: время замедления в секундах
  /// Рекомендуемые значения: 0.5-3.0
  final double decelerationDuration;

  /// Скорость вращения от 0.0 (не включая) до 1.0 (быстро)
  /// Допустимые значения: 0.0 < speed <= 1.0
  final double speed;

  /// Callback который вызывается когда колесо достигает постоянной скорости
  /// Используйте это для выполнения асинхронных операций
  /// После завершения операции вызовите notifyExternalFunctionComplete()
  final Function()? onConstantSpeedReached;

  /// Разрешить вращение по нажатию на колесо
  /// По умолчанию false - колесо не крутится при нажатии
  final bool enableTapToSpin;

  const FortuneWheelWidget({
    super.key,
    this.onResult,
    this.width,
    this.height,
    this.spinDuration = 3.0,
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.sectionsCount = 10,
    this.showSectionIndex = false,
    this.theme = const FortuneWheelTheme(),
    this.accelerationDuration = 0.5,
    this.decelerationDuration = 2.0,
    this.speed = 0.7,
    this.onConstantSpeedReached,
    this.enableTapToSpin = false,
  }) : assert(
         speed > 0.0 && speed <= 1.0,
         'Speed must be between 0.0 (exclusive) and 1.0',
       );

  @override
  State<FortuneWheelWidget> createState() => FortuneWheelWidgetState();
}

class FortuneWheelWidgetState extends State<FortuneWheelWidget> {
  late FortuneWheelGame game;

  @override
  void initState() {
    super.initState();
    game = FortuneWheelGame(
      onResult: widget.onResult,
      spinDuration: widget.spinDuration,
      pointerPosition: widget.pointerPosition,
      pointerOffset: widget.pointerOffset,
      sectionsCount: widget.sectionsCount,
      showSectionIndex: widget.showSectionIndex,
      theme: widget.theme,
      accelerationDuration: widget.accelerationDuration,
      decelerationDuration: widget.decelerationDuration,
      speed: widget.speed,
      enableTapToSpin: widget.enableTapToSpin,
    )..onConstantSpeedReached = widget.onConstantSpeedReached;
  }

  /// Программно запускает вращение колеса (без конкретной цели)
  /// [duration] - время вращения в секундах (опционально)
  void spin() {
    game.wheel.spin();
  }

  /// Программно запускает вращение на конкретную секцию
  /// [duration] - время вращения в секундах (опционально)
  void spinToSection(int sectionIndex, {double? duration}) {
    game.spinToSection(sectionIndex, duration: duration);
  }

  /// Программно запускает вращение на случайную секцию "Выиграл"
  /// [duration] - время вращения в секундах (опционально)
  void spinToWin({double? duration}) {
    game.spinToWin(duration: duration);
  }

  /// Программно запускает вращение на случайную секцию "Не выиграл"
  /// [duration] - время вращения в секундах (опционально)
  void spinToLose({double? duration}) {
    game.spinToLose(duration: duration);
  }

  /// Уведомляет колесо что внешняя функция завершилась
  /// и можно начинать финальный этап вращения
  void notifyExternalFunctionComplete() {
    game.notifyExternalFunctionComplete();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: GameWidget(game: game),
    );
  }
}

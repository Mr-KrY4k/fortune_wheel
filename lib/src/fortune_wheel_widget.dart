import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'fortune_wheel.dart';
import 'fortune_wheel_theme.dart';
import 'wheel_section.dart';

class FortuneWheelWidget extends StatefulWidget {
  /// Callback который вызывается когда колесо останавливается
  /// Возвращает тип секции (SectionType.win или SectionType.lose)
  final Function(SectionType)? onResult;

  /// Ширина виджета (опционально, по умолчанию занимает всё доступное пространство)
  final double? width;

  /// Высота виджета (опционально, по умолчанию занимает всё доступное пространство)
  final double? height;

  /// Время вращения с постоянной скоростью после завершения внешней функции
  final double spinDuration;

  /// Позиция указателя на колесе
  /// Возможные значения: PointerPosition.top, bottom, left, right
  final PointerPosition pointerPosition;

  /// Насколько указатель заходит внутрь колеса в пикселях
  /// По умолчанию 0.0 - указатель касается края колеса
  final double pointerOffset;

  /// Количество секций на колесе (по умолчанию 10)
  /// Четные индексы - выигрышные, нечетные - проигрышные
  final int sectionsCount;

  /// Показывать индексы секций для отладки
  /// По умолчанию false
  final bool showSectionIndex;

  /// Кастомные секции с возможностью добавить изображения
  /// Если указаны, параметры sectionsCount, winText и loseText игнорируются
  final List<WheelSection>? customSections;

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

  /// Callback который вызывается при ошибке во время выполнения внешней функции
  /// Используется для логирования ошибок и уведомления пользователя
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Разрешить завершение вращения колеса при ошибке
  /// - true (по умолчанию): колесо остановится при ошибке
  /// - false: колесо будет крутиться бесконечно до успешного завершения или вызова notifyExternalFunctionComplete()
  final bool allowSpinCompletionOnError;

  /// Разрешить вращение по нажатию на колесо
  /// По умолчанию false - колесо не крутится при нажатии
  final bool enableTapToSpin;

  /// Текст для секций с выигрышем
  final String? winText;

  /// Текст для секций с проигрышем
  final String? loseText;

  /// Путь к изображению для секций "Выиграл"
  /// Поддерживаемые форматы: .png, .jpg, .jpeg, .svg, .webp
  final String? winImagePath;

  /// Путь к изображению для секций "Не выиграл"
  /// Поддерживаемые форматы: .png, .jpg, .jpeg, .svg, .webp
  final String? loseImagePath;

  /// Показывать текст вместе с изображением
  /// По умолчанию false - показывается только изображение
  final bool showTextWithImage;

  const FortuneWheelWidget({
    super.key,
    this.onResult,
    this.width,
    this.height,
    this.spinDuration = 2.0,
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.sectionsCount = 10,
    this.showSectionIndex = false,
    this.customSections,
    this.theme = const FortuneWheelTheme(),
    this.accelerationDuration = 1.0,
    this.decelerationDuration = 1.0,
    this.speed = 0.2,
    this.onConstantSpeedReached,
    this.onError,
    this.allowSpinCompletionOnError = true,
    this.enableTapToSpin = false,
    this.winText,
    this.loseText,
    this.winImagePath,
    this.loseImagePath,
    this.showTextWithImage = false,
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
    game =
        FortuneWheelGame(
            onResult: widget.onResult,
            spinDuration: widget.spinDuration,
            pointerPosition: widget.pointerPosition,
            pointerOffset: widget.pointerOffset,
            sectionsCount: widget.sectionsCount,
            showSectionIndex: widget.showSectionIndex,
            customSections: widget.customSections,
            theme: widget.theme,
            accelerationDuration: widget.accelerationDuration,
            decelerationDuration: widget.decelerationDuration,
            speed: widget.speed,
            enableTapToSpin: widget.enableTapToSpin,
            allowSpinCompletionOnError: widget.allowSpinCompletionOnError,
            winText: widget.winText,
            loseText: widget.loseText,
            winImagePath: widget.winImagePath,
            loseImagePath: widget.loseImagePath,
            showTextWithImage: widget.showTextWithImage,
          )
          ..onConstantSpeedReached = widget.onConstantSpeedReached
          ..onError = widget.onError;
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
  ///
  /// Параметры (опционально):
  /// - [targetSectionIndex] - конкретный индекс секции для остановки
  /// - [targetSectionType] - тип секции (win/lose) для остановки на случайной секции этого типа
  ///
  /// Если оба параметра указаны, приоритет имеет [targetSectionIndex]
  void notifyExternalFunctionComplete({
    int? targetSectionIndex,
    SectionType? targetSectionType,
  }) {
    game.notifyExternalFunctionComplete(
      targetSectionIndex: targetSectionIndex,
      targetSectionType: targetSectionType,
    );
  }

  /// Уведомляет колесо что во время выполнения внешней функции произошла ошибка
  /// Поведение колеса зависит от параметра allowSpinCompletionOnError
  void notifyExternalFunctionError(Object error, StackTrace stackTrace) {
    game.notifyExternalFunctionError(error, stackTrace);
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

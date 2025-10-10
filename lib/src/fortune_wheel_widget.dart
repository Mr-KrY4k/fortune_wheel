import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'fortune_wheel.dart';
import 'wheel_section.dart';

class FortuneWheelWidget extends StatefulWidget {
  final Function(SectionType)? onResult;
  final double? width;
  final double? height;
  final double spinDuration;
  final Color backgroundColor;
  final PointerPosition pointerPosition;
  final double pointerOffset;
  final double pointerWidth;
  final double pointerHeight;
  final int sectionsCount;
  final bool showSectionIndex;

  const FortuneWheelWidget({
    super.key,
    this.onResult,
    this.width,
    this.height,
    this.spinDuration = 3.0,
    this.backgroundColor = const Color(0xFF000000),
    this.pointerPosition = PointerPosition.top,
    this.pointerOffset = 0.0,
    this.pointerWidth = 25.0,
    this.pointerHeight = 40.0,
    this.sectionsCount = 10,
    this.showSectionIndex = false,
  });

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
      bgColor: widget.backgroundColor,
      pointerPosition: widget.pointerPosition,
      pointerOffset: widget.pointerOffset,
      pointerWidth: widget.pointerWidth,
      pointerHeight: widget.pointerHeight,
      sectionsCount: widget.sectionsCount,
      showSectionIndex: widget.showSectionIndex,
    );
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: GameWidget(game: game),
    );
  }
}

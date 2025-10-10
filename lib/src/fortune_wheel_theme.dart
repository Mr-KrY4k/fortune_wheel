import 'package:flutter/material.dart';

/// Тема для указателя колеса
class PointerTheme {
  /// Цвет заливки указателя
  final Color color;

  /// Градиент для указателя (если задан, используется вместо color)
  final Gradient? gradient;

  /// Цвет бордера указателя
  final Color borderColor;

  /// Толщина бордера указателя
  final double borderWidth;

  /// Радиус скругления углов указателя (0 = острый)
  final double borderRadius;

  /// Ширина указателя
  final double width;

  /// Высота указателя
  final double height;

  /// Тень для указателя
  final List<BoxShadow>? shadows;

  const PointerTheme({
    this.color = Colors.yellow,
    this.gradient,
    this.borderColor = const Color(0xFFBD8A31),
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.width = 25.0,
    this.height = 40.0,
    this.shadows,
  });
}

/// Тема для текста на секциях
class SectionTextTheme {
  /// Цвет текста
  final Color color;

  /// Размер шрифта
  final double fontSize;

  /// Жирность шрифта
  final FontWeight fontWeight;

  /// Тень текста
  final List<Shadow>? shadows;

  const SectionTextTheme({
    this.color = Colors.white,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.shadows,
  });
}

/// Тема для секций колеса
class WheelSectionsTheme {
  /// Цвета секций (чередуются по порядку)
  final List<Color> colors;

  /// Тема текста
  final SectionTextTheme textTheme;

  /// Цвет бордера вокруг каждой секции
  final Color sectionBorderColor;

  /// Толщина бордера вокруг каждой секции
  final double sectionBorderWidth;

  /// Радиус скругления углов секций
  final double sectionBorderRadius;

  const WheelSectionsTheme({
    this.colors = const [Colors.green, Colors.red],
    this.textTheme = const SectionTextTheme(),
    this.sectionBorderColor = Colors.white,
    this.sectionBorderWidth = 0.0,
    this.sectionBorderRadius = 0.0,
  });
}

/// Тема для бордера колеса
class WheelBorderTheme {
  /// Цвет бордера
  final Color color;

  /// Толщина бордера
  final double width;

  /// Тень колеса
  final List<BoxShadow>? shadows;

  const WheelBorderTheme({
    this.color = Colors.white,
    this.width = 4.0,
    this.shadows,
  });

  /// Бордер с тенью
  static const WheelBorderTheme withShadow = WheelBorderTheme(
    color: Colors.white,
    width: 4.0,
    shadows: [
      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
    ],
  );

  /// Золотой бордер
  static const WheelBorderTheme golden = WheelBorderTheme(
    color: Color(0xFFFFD700),
    width: 5.0,
    shadows: [
      BoxShadow(color: Color(0xFFB8860B), blurRadius: 8, offset: Offset(0, 3)),
    ],
  );

  WheelBorderTheme copyWith({
    Color? color,
    double? width,
    List<BoxShadow>? shadows,
  }) {
    return WheelBorderTheme(
      color: color ?? this.color,
      width: width ?? this.width,
      shadows: shadows ?? this.shadows,
    );
  }
}

/// Тема для центрального круга (вала)
class CenterCircleTheme {
  /// Цвет заливки центрального круга
  final Color color;

  /// Градиент для центрального круга (если задан, используется вместо color)
  final Gradient? gradient;

  /// Размер центрального круга (радиус в пикселях)
  final double radius;

  /// Цвет бордера центрального круга
  final Color borderColor;

  /// Толщина бордера центрального круга
  final double borderWidth;

  /// Тени для центрального круга
  final List<BoxShadow>? shadows;

  const CenterCircleTheme({
    this.color = const Color(0xFF333333),
    this.gradient,
    this.radius = 30.0,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.shadows,
  });

  /// Металлический вал
  static const CenterCircleTheme metallic = CenterCircleTheme(
    gradient: RadialGradient(
      colors: [Color(0xFF888888), Color(0xFF555555), Color(0xFF333333)],
      stops: [0.0, 0.5, 1.0],
    ),
    radius: 35.0,
    borderColor: Color(0xFF999999),
    borderWidth: 3.0,
    shadows: [
      BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
    ],
  );

  /// Золотой вал
  static const CenterCircleTheme golden = CenterCircleTheme(
    gradient: RadialGradient(
      colors: [Color(0xFFFFD700), Color(0xFFDAA520), Color(0xFFB8860B)],
      stops: [0.0, 0.5, 1.0],
    ),
    radius: 35.0,
    borderColor: Color(0xFFFFD700),
    borderWidth: 4.0,
    shadows: [
      BoxShadow(color: Color(0xFFB8860B), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );
}

/// Полная тема для колеса фортуны
class FortuneWheelTheme {
  /// Цвет фона игры
  final Color backgroundColor;

  /// Тема указателя
  final PointerTheme pointerTheme;

  /// Тема секций
  final WheelSectionsTheme sectionsTheme;

  /// Тема бордера колеса
  final WheelBorderTheme borderTheme;

  /// Тема центрального круга (вала)
  final CenterCircleTheme? centerCircleTheme;

  const FortuneWheelTheme({
    this.backgroundColor = Colors.black,
    this.pointerTheme = const PointerTheme(),
    this.sectionsTheme = const WheelSectionsTheme(),
    this.borderTheme = const WheelBorderTheme(),
    this.centerCircleTheme,
  });
}

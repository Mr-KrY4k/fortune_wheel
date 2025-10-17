import 'package:flutter/material.dart';

enum SpinResult { win, lose }

enum PointerPosition { top, bottom, left, right }

class WheelSection {
  final SpinResult type;
  final Color color;
  final String label;

  /// Путь к изображению (asset path)
  /// Если указан, изображение будет отображаться вместо или вместе с текстом
  /// Поддерживаемые форматы: .png, .jpg, .jpeg, .webp, .svg
  /// Тип изображения определяется автоматически по расширению файла
  final String? imagePath;

  /// Показывать текст вместе с изображением
  /// По умолчанию false - показывается только изображение
  final bool showLabelWithImage;

  const WheelSection({
    required this.type,
    required this.color,
    required this.label,
    this.imagePath,
    this.showLabelWithImage = false,
  });

  /// Определяет тип изображения по расширению файла
  bool get isSvg {
    if (imagePath == null) return false;
    return imagePath!.toLowerCase().endsWith('.svg');
  }

  /// Проверяет, является ли изображение растровым (PNG, JPG и т.д.)
  bool get isRasterImage {
    if (imagePath == null) return false;
    final path = imagePath!.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp');
  }
}

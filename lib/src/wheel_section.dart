import 'package:flutter/material.dart';

enum SectionType { win, lose }

enum PointerPosition { top, bottom, left, right }

class WheelSection {
  final SectionType type;
  final Color color;
  final String label;

  const WheelSection({
    required this.type,
    required this.color,
    required this.label,
  });
}

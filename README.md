# Fortune Spinner

Колесо фортуны на Flame для Flutter с двумя вариантами: "Выиграл" и "Не выиграл".

## Особенности

- 🎯 Настраиваемое количество секций (по умолчанию 10)
- 🎨 Красивая анимация вращения
- 🎲 Случайный результат
- ⚡ Построено на Flame Engine
- 📱 Легко интегрируется в любое Flutter приложение
- ⚙️ Полная настройка внешнего вида

## Установка

Добавьте в `pubspec.yaml`:

```yaml
dependencies:
  fortune_spinner:
    git:
      url: https://github.com/your-repo/fortune_spinner.git
```

Или локально:

```yaml
dependencies:
  fortune_spinner:
    path: ../fortune_spinner
```

## Использование

```dart
import 'package:flutter/material.dart';
import 'package:fortune_spinner/fortune_spinner.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _result = 'Нажмите на колесо';

  void _onSpinResult(SectionType result) {
    setState(() {
      _result = result == SectionType.win 
        ? 'Вы выиграли!' 
        : 'Не повезло';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              width: 350,
              height: 350,
              child: FortuneWheelWidget(
                onResult: _onSpinResult,
                spinDuration: 5.0, // Время вращения в секундах (по умолчанию 3.0)
                backgroundColor: Colors.blue, // Цвет фона (по умолчанию черный)
                pointerPosition: PointerPosition.bottom, // Позиция стрелки (по умолчанию top)
                pointerOffset: 20.0, // Насколько стрелка заходит внутрь колеса (по умолчанию 0)
                pointerWidth: 30.0, // Ширина стрелки (по умолчанию 25.0)
                pointerHeight: 50.0, // Высота стрелки (по умолчанию 40.0)
                sectionsCount: 8, // Количество секций (по умолчанию 10)
                showSectionIndex: true, // Показать индексы для отладки (по умолчанию false)
              ),
            ),
            Text(_result),
          ],
        ),
      ),
    );
  }
}
```

## Запуск примера

```bash
cd example
flutter run
```

## Как работает

1. **Нажмите на колесо** - колесо начнёт вращаться
2. **Ждите остановки** - колесо замедлится и остановится
3. **Получите результат** - callback вернёт `SectionType.win` или `SectionType.lose`

**Распределение секций:**
- Четные индексы (0, 2, 4, ...) - "Выиграл" (зеленый)
- Нечетные индексы (1, 3, 5, ...) - "Не выиграл" (красный)

Примеры:
- `sectionsCount: 6` → 3 секции "Выиграл", 3 секции "Не выиграл"
- `sectionsCount: 10` → 5 секций "Выиграл", 5 секций "Не выиграл" (по умолчанию)
- `sectionsCount: 20` → 10 секций "Выиграл", 10 секций "Не выиграл"

## Режим отладки

Для тестирования и отладки можно включить отображение индексов секций:

```dart
FortuneWheelWidget(
  onResult: _onSpinResult,
  showSectionIndex: true, // Показывает индексы на каждой секции
)
```

В этом режиме на каждой секции будет отображаться её индекс (крупным шрифтом на краю) и текст (меньшим шрифтом ближе к центру).

## Программное управление вращением

Можно программно управлять результатом вращения:

```dart
class _MyHomePageState extends State<MyHomePage> {
  final wheelKey = GlobalKey<FortuneWheelWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FortuneWheelWidget(
          key: wheelKey,
          onResult: (result) => print('Результат: $result'),
          showSectionIndex: true, // Для визуальной проверки
        ),
        
        // Управление по результату
        ElevatedButton(
          onPressed: () => wheelKey.currentState?.spinToWin(),
          child: Text('Выиграть'),
        ),
        ElevatedButton(
          onPressed: () => wheelKey.currentState?.spinToLose(),
          child: Text('Проиграть'),
        ),
        
        // Управление по конкретной секции (для отладки)
        ElevatedButton(
          onPressed: () => wheelKey.currentState?.spinToSection(5),
          child: Text('Секция 5'),
        ),
      ],
    );
  }
}
```

### Доступные методы:

- **`spinToWin({double? duration})`** - останавливается на случайной зеленой секции "Выиграл"
- **`spinToLose({double? duration})`** - останавливается на случайной красной секции "Не выиграл"
- **`spinToSection(int index, {double? duration})`** - останавливается на конкретной секции по индексу

Все методы принимают опциональный параметр `duration` для переопределения времени вращения:

```dart
// Быстрое вращение (2 секунды)
wheelKey.currentState?.spinToWin(duration: 2.0);

// Медленное вращение (10 секунд)
wheelKey.currentState?.spinToLose(duration: 10.0);

// Использовать время по умолчанию из виджета
wheelKey.currentState?.spinToWin();
```

Колесо сделает 3-5 полных оборотов с небольшим случайным отклонением от центра секции для реалистичности.

## Параметры

### FortuneWheelWidget

- `onResult` - callback, вызывается когда колесо останавливается
- `width` - ширина виджета (опционально)
- `height` - высота виджета (опционально)
- `spinDuration` - длительность вращения в секундах (по умолчанию 3.0)
- `backgroundColor` - цвет фона игры (по умолчанию черный)
- `pointerPosition` - позиция стрелки: `PointerPosition.top`, `bottom`, `left`, `right` (по умолчанию top)
- `pointerOffset` - насколько стрелка заходит внутрь колеса в пикселях (по умолчанию 0.0)
- `pointerWidth` - ширина стрелки в пикселях, адаптируется под размер колеса (по умолчанию 25.0)
- `pointerHeight` - высота стрелки в пикселях, адаптируется под размер колеса (по умолчанию 40.0)
- `sectionsCount` - количество секций на колесе (по умолчанию 10, четные - выиграл, нечетные - проиграл)
- `showSectionIndex` - показывать индексы секций для отладки (по умолчанию false)

## Требования

- Flutter: >= 1.17.0
- Dart: ^3.8.0
- Flame: ^1.32.0


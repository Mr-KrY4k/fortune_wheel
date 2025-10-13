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

- **`spin()`** - запускает случайное вращение колеса без конкретной цели
- **`spinToWin({double? duration})`** - останавливается на случайной зеленой секции "Выиграл"
- **`spinToLose({double? duration})`** - останавливается на случайной красной секции "Не выиграл"
- **`spinToSection(int index, {double? duration})`** - останавливается на конкретной секции по индексу
- **`notifyExternalFunctionComplete({int? targetSectionIndex, SectionType? targetSectionType})`** - уведомляет колесо об успешном завершении внешней функции. Опционально можно указать целевую секцию (индекс или тип)
- **`notifyExternalFunctionError(Object error, StackTrace stackTrace)`** - уведомляет колесо об ошибке во время выполнения внешней функции

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

## Обработка асинхронных операций и ошибок

Колесо фортуны поддерживает выполнение асинхронных операций (например, запросов к API) во время вращения. Когда колесо достигает постоянной скорости, вызывается callback `onConstantSpeedReached`, который можно использовать для выполнения внешних операций.

### Базовое использование

```dart
class _MyHomePageState extends State<MyHomePage> {
  final wheelKey = GlobalKey<FortuneWheelWidgetState>();

  void _onConstantSpeedReached() {
    // Выполняем асинхронную операцию
    _performApiCall();
  }

  Future<void> _performApiCall() async {
    try {
      // Запрос к API
      final result = await fetchDataFromApi();
      
      // API может вернуть конкретный результат (индекс секции или тип)
      // Вариант 1: Остановиться на конкретной секции
      wheelKey.currentState?.notifyExternalFunctionComplete(
        targetSectionIndex: result.sectionIndex,
      );
      
      // Вариант 2: Остановиться на случайной секции нужного типа (win/lose)
      // wheelKey.currentState?.notifyExternalFunctionComplete(
      //   targetSectionType: result.isWin ? SectionType.win : SectionType.lose,
      // );
      
      // Вариант 3: Случайная остановка (без параметров)
      // wheelKey.currentState?.notifyExternalFunctionComplete();
    } catch (error, stackTrace) {
      // При ошибке уведомляем колесо, передавая информацию об ошибке
      wheelKey.currentState?.notifyExternalFunctionError(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FortuneWheelWidget(
      key: wheelKey,
      onConstantSpeedReached: _onConstantSpeedReached,
      onResult: (result) => print('Результат: $result'),
    );
  }
}
```

### Обработка ошибок с уведомлением пользователя

Callback `onError` используется для логирования и уведомления пользователя об ошибках:

```dart
class _MyHomePageState extends State<MyHomePage> {
  final wheelKey = GlobalKey<FortuneWheelWidgetState>();

  void _onConstantSpeedReached() {
    _performApiCall();
  }

  Future<void> _performApiCall() async {
    try {
      // Симулируем запрос к API
      await Future.delayed(const Duration(seconds: 2));
      
      // Можете раскомментировать для тестирования ошибки
      // throw Exception('API Error: Connection timeout');
      
      wheelKey.currentState?.notifyExternalFunctionComplete();
    } catch (error, stackTrace) {
      wheelKey.currentState?.notifyExternalFunctionError(error, stackTrace);
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    debugPrint('Ошибка при выполнении API запроса: $error');
    
    // Показываем пользователю сообщение об ошибке
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FortuneWheelWidget(
      key: wheelKey,
      onConstantSpeedReached: _onConstantSpeedReached,
      onError: _onError,
      // allowSpinCompletionOnError: true, // По умолчанию - остановиться при ошибке
      onResult: (result) => print('Результат: $result'),
    );
  }
}
```

### Настройка поведения при ошибке

Параметр `allowSpinCompletionOnError` контролирует поведение колеса при ошибке:

```dart
// Вариант 1: Остановиться при ошибке (по умолчанию)
FortuneWheelWidget(
  key: wheelKey,
  onConstantSpeedReached: _onConstantSpeedReached,
  onError: _onError, // Для уведомления пользователя
  allowSpinCompletionOnError: true, // Остановится
  onResult: (result) => print('Результат: $result'),
)

// Вариант 2: Крутиться бесконечно до успеха
FortuneWheelWidget(
  key: wheelKey,
  onConstantSpeedReached: _onConstantSpeedReached,
  onError: _onError, // Для уведомления пользователя
  allowSpinCompletionOnError: false, // Будет крутиться до успеха
  onResult: (result) => print('Результат: $result'),
)
```

При `allowSpinCompletionOnError: false` колесо будет крутиться бесконечно при ошибках, пока не получит успешный результат через `notifyExternalFunctionComplete()`.

### Важно

- **`allowSpinCompletionOnError`** (по умолчанию `true`):
  - **`true`** = колесо остановится при ошибке
  - **`false`** = колесо будет крутиться бесконечно до успешного завершения
- **`onError`** - callback для логирования и уведомления пользователя об ошибках
- Всегда оборачивайте асинхронные операции в `try-catch` блок
- При успешном выполнении используйте `notifyExternalFunctionComplete()` с параметрами:
  - **`targetSectionIndex`** - конкретный индекс секции (0-9 по умолчанию)
  - **`targetSectionType`** - тип секции (`SectionType.win` или `SectionType.lose`)
  - Без параметров - случайная остановка
- При ошибке используйте `notifyExternalFunctionError(error, stackTrace)`

### Динамическая установка результата

API может вернуть результат, на котором должно остановиться колесо. Используйте параметры `notifyExternalFunctionComplete()`:

```dart
Future<void> _performApiCall() async {
  try {
    final apiResponse = await yourApiCall();
    
    // Если API возвращает конкретный индекс секции
    if (apiResponse.hasSpecificSection) {
      wheelKey.currentState?.notifyExternalFunctionComplete(
        targetSectionIndex: apiResponse.sectionIndex,
      );
    }
    // Если API возвращает только win/lose
    else if (apiResponse.hasResult) {
      wheelKey.currentState?.notifyExternalFunctionComplete(
        targetSectionType: apiResponse.isWinner ? SectionType.win : SectionType.lose,
      );
    }
    // Если API не возвращает результат - случайная остановка
    else {
      wheelKey.currentState?.notifyExternalFunctionComplete();
    }
  } catch (error, stackTrace) {
    wheelKey.currentState?.notifyExternalFunctionError(error, stackTrace);
  }
}
```

## Параметры

### FortuneWheelWidget

- `onResult` - callback, вызывается когда колесо останавливается
- `onConstantSpeedReached` - callback, вызывается когда колесо достигает постоянной скорости (опционально)
- `onError` - callback для логирования ошибок и уведомления пользователя (опционально)
- `allowSpinCompletionOnError` - разрешить завершение вращения при ошибке: `true` (по умолчанию) = остановиться, `false` = крутиться бесконечно
- `width` - ширина виджета (опционально)
- `height` - высота виджета (опционально)
- `spinDuration` - длительность вращения в секундах после завершения внешней функции (по умолчанию 3.0)
- `accelerationDuration` - время разгона колеса в секундах (по умолчанию 0.5)
- `decelerationDuration` - коэффициент/время замедления (по умолчанию 2.0)
- `speed` - скорость вращения от 0.0 (не включая) до 1.0 (по умолчанию 0.7)
- `backgroundColor` - цвет фона игры (по умолчанию черный)
- `pointerPosition` - позиция стрелки: `PointerPosition.top`, `bottom`, `left`, `right` (по умолчанию top)
- `pointerOffset` - насколько стрелка заходит внутрь колеса в пикселях (по умолчанию 0.0)
- `pointerWidth` - ширина стрелки в пикселях, адаптируется под размер колеса (по умолчанию 25.0)
- `pointerHeight` - высота стрелки в пикселях, адаптируется под размер колеса (по умолчанию 40.0)
- `sectionsCount` - количество секций на колесе (по умолчанию 10, четные - выиграл, нечетные - проиграл)
- `showSectionIndex` - показывать индексы секций для отладки (по умолчанию false)
- `enableTapToSpin` - разрешить вращение при нажатии на колесо (по умолчанию false)
- `winText` - текст для секций с выигрышем (по умолчанию 'Выиграл')
- `loseText` - текст для секций с проигрышем (по умолчанию 'Не выиграл')
- `theme` - тема для настройки внешнего вида колеса (см. раздел "Система тем")

## Требования

- Flutter: >= 1.17.0
- Dart: ^3.8.0
- Flame: ^1.32.0

---

# 🎨 Система тем

Полная система кастомизации внешнего вида колеса фортуны.

## Использование тем

### Базовое использование

```dart
FortuneWheelWidget(
  theme: FortuneWheelTheme(
    backgroundColor: Colors.black,
    pointerTheme: PointerTheme(
      color: Colors.yellow,
      borderRadius: 12.0,
    ),
    sectionsTheme: WheelSectionsTheme(
      colors: [Colors.green, Colors.red],
      sectionBorderRadius: 15.0,
    ),
  ),
  onResult: (result) => print(result),
)
```

### Указатель с тенью

```dart
pointerTheme: PointerTheme(
  gradient: LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
  ),
  borderRadius: 10.0,
  shadows: [
    BoxShadow(
      color: Colors.black45,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ],
)
```

### Центральный круг (вал)

Добавьте реалистичный вал в центре колеса:

```dart
FortuneWheelTheme(
  centerCircleTheme: CenterCircleTheme(
    gradient: RadialGradient(
      colors: [Color(0xFF888888), Color(0xFF555555), Color(0xFF333333)],
      stops: [0.0, 0.5, 1.0],
    ),
    radius: 35.0,
    borderColor: Color(0xFF999999),
    borderWidth: 3.0,
    shadows: [
      BoxShadow(
        color: Colors.black54,
        blurRadius: 10,
        offset: Offset(0, 3),
      ),
    ],
  ),
)
```

Или используйте готовый:
```dart
centerCircleTheme: CenterCircleTheme.metallic, // Металлический вал
centerCircleTheme: CenterCircleTheme.golden,   // Золотой вал
```

### Секции со скругленными углами

```dart
sectionsTheme: WheelSectionsTheme(
  colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
  sectionBorderRadius: 20.0, // Скругление всех 3 углов
  sectionBorderColor: Colors.white,
  sectionBorderWidth: 2.0,
)
```

### Множество цветов

```dart
sectionsTheme: WheelSectionsTheme(
  colors: [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ],
)
```

## Компоненты темы

### FortuneWheelTheme

| Параметр | Тип | Описание |
|----------|-----|----------|
| backgroundColor | Color | Цвет фона игры |
| pointerTheme | PointerTheme | Тема указателя |
| sectionsTheme | WheelSectionsTheme | Тема секций |
| borderTheme | WheelBorderTheme | Тема бордера колеса |
| centerCircleTheme | CenterCircleTheme? | Тема центрального круга (вала) |

### PointerTheme

| Параметр | Тип | Описание |
|----------|-----|----------|
| color | Color | Цвет заливки |
| gradient | Gradient? | Градиент (приоритет над color) |
| borderColor | Color | Цвет бордера |
| borderWidth | double | Толщина бордера |
| borderRadius | double | Радиус скругления углов треугольника |
| width | double | Ширина указателя |
| height | double | Высота указателя |
| shadows | List\<BoxShadow\>? | Тени для указателя |

### WheelSectionsTheme

| Параметр | Тип | Описание |
|----------|-----|----------|
| colors | List\<Color\> | Цвета секций (чередуются) |
| sectionBorderColor | Color | Цвет бордера вокруг секций |
| sectionBorderWidth | double | Толщина бордера вокруг секций |
| sectionBorderRadius | double | Радиус скругления всех 3 углов секций |
| textTheme | SectionTextTheme | Тема текста |

### SectionTextTheme

| Параметр | Тип | Описание |
|----------|-----|----------|
| color | Color | Цвет текста |
| fontSize | double | Размер шрифта |
| fontWeight | FontWeight | Жирность шрифта |
| shadows | List\<Shadow\>? | Тени текста |

## Настройка текста секций

Вы можете полностью настраивать текст и его отображение на секциях колеса фортуны.

### Пользовательские тексты

Передайте свои тексты для секций выигрыша и проигрыша:

```dart
FortuneWheelWidget(
  winText: '🎉 Приз!',
  loseText: '😔 Попробуй еще',
  // ... другие параметры
)
```

**По умолчанию:**
- `winText`: 'Выиграл'
- `loseText`: 'Не выиграл'

### Комбинирование текста и темы

```dart
FortuneWheelWidget(
  // Пользовательские тексты
  winText: '🎉 Приз!',
  loseText: '😔 Попробуй еще',
  
  // Стилизация текста
  theme: FortuneWheelTheme(
    sectionsTheme: WheelSectionsTheme(
      colors: [Colors.green, Colors.red],
      textTheme: SectionTextTheme(
        color: Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    ),
  ),
)
```

### CenterCircleTheme

| Параметр | Тип | Описание |
|----------|-----|----------|
| color | Color | Цвет заливки круга |
| gradient | Gradient? | Градиент (приоритет над color) |
| radius | double | Радиус центрального круга |
| borderColor | Color | Цвет бордера круга |
| borderWidth | double | Толщина бордера круга |
| shadows | List\<BoxShadow\>? | Тени для объема |

### WheelBorderTheme

| Параметр | Тип | Описание |
|----------|-----|----------|
| color | Color | Цвет бордера |
| width | double | Толщина бордера |

## Полный пример темы

```dart
FortuneWheelWidget(
  theme: FortuneWheelTheme(
    backgroundColor: Color(0xFF1a1a1a),
    
    pointerTheme: PointerTheme(
      gradient: LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
      ),
      borderRadius: 10.0,
      borderColor: Color(0xFFB8860B),
      borderWidth: 2.5,
      shadows: [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    
    sectionsTheme: WheelSectionsTheme(
      colors: [Colors.green, Colors.red],
      sectionBorderRadius: 15.0,
      sectionBorderColor: Colors.white,
      sectionBorderWidth: 2.0,
      textTheme: SectionTextTheme(
        color: Colors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 3,
            color: Colors.black45,
          ),
        ],
      ),
    ),
    
    borderTheme: WheelBorderTheme(
      color: Colors.white,
      width: 4.0,
    ),
    
    centerCircleTheme: CenterCircleTheme.metallic,
  ),
)
```

## Советы по дизайну

1. **Контрастность**: Убедитесь, что текст хорошо виден на фоне секций
2. **Цвета**: Используйте 2-6 цветов для секций для лучшего восприятия
3. **Скругление**: `sectionBorderRadius` 10-25 для современных мягких форм
4. **Градиенты**: Используйте радиальный градиент для центрального круга для эффекта объема
5. **Тени**: Добавляйте тени к указателю и центральному кругу для глубины
6. **Центральный круг**: Радиус 25-40px создает реалистичный эффект вала


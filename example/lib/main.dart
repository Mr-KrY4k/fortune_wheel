import 'package:flutter/material.dart';
import 'package:fortune_spinner/fortune_spinner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fortune Spinner Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final wheelKey = GlobalKey<FortuneWheelWidgetState>();

  void _onSpinResult(SectionType result) {
    // Показываем результат в диалоговом окне
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            result == SectionType.win
                ? '🎉 Поздравляем!'
                : '😔 Попробуйте ещё раз',
            textAlign: TextAlign.center,
          ),
          content: Text(
            result == SectionType.win
                ? 'Вы выиграли!'
                : 'Не повезло, попробуйте еще раз',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _spin() {
    // Просто крутим колесо без конкретной цели
    wheelKey.currentState?.spin();
  }

  void _spinToWin() {
    wheelKey.currentState?.spinToWin();
  }

  void _spinToLose() {
    wheelKey.currentState?.spinToLose();
  }

  // Вызывается когда колесо достигло постоянной скорости
  void _onConstantSpeedReached() {
    // Симулируем асинхронную операцию (например, запрос к API)
    Future.delayed(const Duration(seconds: 2), () {
      // Уведомляем колесо что можно начинать финальный этап
      wheelKey.currentState?.notifyExternalFunctionComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Колесо Фортуны'),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 30),
              Expanded(
                child: Center(
                  child: FortuneWheelWidget(
                    key: wheelKey,
                    onResult: _onSpinResult,
                    onConstantSpeedReached: _onConstantSpeedReached,
                    pointerOffset: 20,
                    sectionsCount: 10,
                    accelerationDuration: 1.0,
                    spinDuration: 2.0,
                    decelerationDuration: 1.0,
                    speed: 0.2,
                    theme: FortuneWheelTheme(
                      backgroundColor: Colors.transparent,
                      pointerTheme: PointerTheme(
                        gradient: LinearGradient(
                          colors: [Color(0xFFCC890B), Color(0xFFFFF38F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 1.82,
                            offset: Offset(0, 4.37),
                          ),
                        ],
                      ),
                      sectionsTheme: WheelSectionsTheme(
                        colors: [
                          Color(0xFF1FA863),
                          Color(0xFF1FA863).withValues(alpha: 0.5),
                        ],
                        sectionBorderRadius: 10,
                        sectionBorderWidth: 5,
                        sectionBorderColor: Colors.white,
                      ),
                      borderTheme: WheelBorderTheme(
                        color: Colors.transparent,
                        width: 0,
                      ),
                      centerCircleTheme: CenterCircleTheme(
                        color: Colors.white,
                        borderColor: Color(0xFFF07820),
                        borderWidth: 7,
                        radius: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Кнопки с целевым результатом
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _spinToWin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Выиграть'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _spinToLose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Проиграть'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Кнопка простого вращения
              ElevatedButton(
                onPressed: _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Крутить'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

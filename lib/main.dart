import 'dart:async';
import 'dart:math';
import 'package:cronometro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cronometro/notifications/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize(); // INICIALIZA AS NOTIFICAÇÕES
  await Permission.notification.request(); // ES NECESARIO AUTORIZAR POR LA VERSION
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimerViewModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRONOMETRO', // TITULO DE LA BARRA
        theme: ThemeData.dark(),
        home: const TimerScreen(),
      ),
    );
  }
}

class TimerViewModel extends ChangeNotifier {
  late Stopwatch _stopwatch;
  Timer? _timer;
  final List<Map<String, String>> _laps = [];

  TimerViewModel() {
    _stopwatch = Stopwatch();
  }

  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
  String get elapsedTime => _formatTime(_stopwatch.elapsedMilliseconds);
  List<Map<String, String>> get laps => _laps;

  void startTimer() { // INICIAR CRONOMETRO
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        notifyListeners();
      });

      NotificationService.showOngoingNotification(
        "Cronômetro em andamento",
        "Tempo: ${elapsedTime}",
      );
    }
  }

  void pauseTimer() { // PAUSAR CRONOMETRO
    _stopwatch.stop();
    _timer?.cancel();
    notifyListeners();

    NotificationService.cancelOngoingNotification();

    // Notificação após 10 segundos de pausa
    Timer(const Duration(seconds: 10), () {
      if (!_stopwatch.isRunning) {
        NotificationService.showPauseReminder();
      }
    });
  }

  void resetTimer() { // REINCIAR CRONOMETRO
    _stopwatch.reset();
    _laps.clear();
    notifyListeners();
    NotificationService.cancelOngoingNotification();
  }

  void addLap() { // REGISTRAR VUELTA
    if (_stopwatch.isRunning) {
      String lapTime = _formatTime(_stopwatch.elapsedMilliseconds);
      _laps.insert(0, {
        'vuelta': lapTime,
        'total': elapsedTime,
      });
      notifyListeners();

      NotificationService.showLapNotification(lapTime, elapsedTime);
    }
  }

  String _formatTime(int milliseconds) {
    int centiseconds = (milliseconds / 10).truncate();
    int seconds = (centiseconds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String centisecondsStr = (centiseconds % 100).toString().padLeft(2, '0');
    return "$minutesStr:$secondsStr:$centisecondsStr";
  }
}

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timerViewModel = Provider.of<TimerViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.black12, // FONDO
      appBar: AppBar(
        title: const Text(
          'CRONOMETRO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black12,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Círculo animado
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Semantics(
              label: 'Progresso do cronômetro: ${timerViewModel.elapsedTime}', // Descripción accesible
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: timerViewModel.elapsedMilliseconds / 60000),
                duration: const Duration(milliseconds: 100),
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: TimerPainter(progress: value),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Text(
                          timerViewModel.elapsedTime,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 50),

          // Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              // SEMANTICS BOTONES
              children: [
                Semantics(
                  label: 'Iniciar cronômetro',
                  button: true,
                  child: _buildButton('Iniciar', timerViewModel.startTimer),
                ),
                Semantics(
                  label: 'Pausar cronômetro',
                  button: true,
                  child: _buildButton('Pausar', timerViewModel.pauseTimer),
                ),
                Semantics(
                  label: 'Reiniciar cronômetro',
                  button: true,
                  child: _buildButton('Reiniciar', timerViewModel.resetTimer),
                ),
                Semantics(
                  label: 'Registrar volta',
                  button: true,
                  child: _buildButton('Vuelta', timerViewModel.addLap),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Lista de vueltas
          Expanded(
            child: ListView.builder(
              itemCount: timerViewModel.laps.length,
              itemBuilder: (context, index) {
                final lap = timerViewModel.laps[index];
                return Semantics(
                  label: 'Volta ${index + 1} com tempo: ${lap['vuelta']} e tempo total: ${lap['total']}',
                  child: ListTile(
                    title: Text(
                      'Volta ${index + 1}: ${lap['vuelta']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Tempo total: ${lap['total']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Botones estilizados
  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800], // Color oscuro
        foregroundColor: Colors.white, // Texto blanco
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      child: Text(text),
    );
  }
}

// CIRCULO ANIMADO
class TimerPainter extends CustomPainter {
  final double progress;

  TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.grey[800]! // Fondo oscuro
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    Paint progressPaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2 - 8;

    canvas.drawCircle(center, radius, backgroundPaint);

    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

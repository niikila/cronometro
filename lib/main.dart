import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimerViewModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cronômetro',
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

  void startTimer() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        notifyListeners();
      });
    }
  }

  void pauseTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _stopwatch.reset();
    _laps.clear();
    notifyListeners();
  }

  void addLap() {
    if (_stopwatch.isRunning) {
      _laps.insert(0, {
        'vuelta': _formatTime(_stopwatch.elapsedMilliseconds),
        'total': elapsedTime,
      });git pu
      notifyListeners();
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cronometro', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Círculo animado
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
                begin: 0, end: timerViewModel.elapsedMilliseconds / 60000),
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
                          fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 50),

          // Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('Iniciar', timerViewModel.startTimer),
                _buildButton('Pausar', timerViewModel.pauseTimer),
                _buildButton('Reiniciar', timerViewModel.resetTimer),
                _buildButton('Vuelta', timerViewModel.addLap),
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
                return ListTile(
                  title: Text(
                    'Volta ${index + 1}: ${lap['vuelta']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Tempo total: ${lap['total']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir botones estilizados
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

// Círculo animado que muestra el progreso
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
      ..color = Colors.orange
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

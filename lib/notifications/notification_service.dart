import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  // Instancia del plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Inicialización del plugin (debe llamarse en main)
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);


  }

  // Notificación  al iniciar cronômetro
  static Future<void> showOngoingNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'cronometro_channel',
      'Cronômetro',
      channelDescription: 'Notificações do cronômetro',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      onlyAlertOnce: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Notificación cuando se registra una vuelta - Lap
  static Future<void> showLapNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'laps_channel',
      'Voltas',
      channelDescription: 'Notificações de voltas do cronômetro',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> showPauseReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pause_channel',
      'Lembrete de pausa',
      channelDescription: 'Notificação quando o cronômetro estiver pausado',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      1,
      'Cronômetro pausado',
      'Você pausou o cronômetro. Deseja retomar?',
      notificationDetails,
    );
  }

  // Notificación sugerindo retomar luego de pausar
  static Future<void> showReminderNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Lembretes',
      channelDescription: 'Sugestões após pausa',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      2,
      'Cronômetro pausado',
      'Deseja retomar a contagem?',
      notificationDetails,
    );
  }

  // Cancelar notificación persistente
  static Future<void> cancelOngoingNotification() async {
    await _notificationsPlugin.cancel(0);
  }
}

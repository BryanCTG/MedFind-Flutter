import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // En web no se inicializa (no es compatible)
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  static Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    if (kIsWeb) return; // Web no soporta notificaciones locales

    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'medfind_channel',
        'MedFind',
        channelDescription: 'Notificaciones de MedFind',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, titulo, cuerpo, detalles);
  }

  static Future<void> medicamentoDisponible(String nombre) async {
    await mostrar(
      id: 1,
      titulo: 'Medicamento disponible',
      cuerpo: '$nombre ya está en stock.',
    );
  }

  static Future<void> medicamentoAgotado(String nombre) async {
    await mostrar(
      id: 2,
      titulo: 'Stock agotado',
      cuerpo: '$nombre se ha agotado.',
    );
  }
}
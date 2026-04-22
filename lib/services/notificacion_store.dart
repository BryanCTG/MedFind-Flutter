import 'package:flutter/material.dart';

// ── Modelo ──────────────────────────────────────────────────────────────────
class AppNotificacion {
  final String titulo;
  final String cuerpo;
  final IconData icono;
  final Color color;
  final DateTime fecha;
  bool leida;

  AppNotificacion({
    required this.titulo,
    required this.cuerpo,
    required this.icono,
    required this.color,
    required this.fecha,
    this.leida = false,
  });
}

// ── Singleton ChangeNotifier ─────────────────────────────────────────────────
class NotificacionStore extends ChangeNotifier {
  static final NotificacionStore _instance = NotificacionStore._internal();
  factory NotificacionStore() => _instance;
  NotificacionStore._internal();

  // Datos iniciales de ejemplo (se muestran sólo la primera vez)
  final List<AppNotificacion> _notificaciones = [
    AppNotificacion(
      titulo: 'Pedido en camino',
      cuerpo: 'Tu pedido anterior está siendo preparado y saldrá pronto.',
      icono: Icons.delivery_dining,
      color: Color(0xFF00BCD4),
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      leida: true,
    ),
    AppNotificacion(
      titulo: 'Recordatorio de medicación',
      cuerpo: 'Recuerda tomar tu Vitamina C. Tu salud es lo más importante.',
      icono: Icons.alarm,
      color: Colors.purple,
      fecha: DateTime.now().subtract(const Duration(days: 2)),
      leida: true,
    ),
  ];

  // ── Accesores ──────────────────────────────────────────────────────────────
  List<AppNotificacion> get notificaciones =>
      List.unmodifiable(_notificaciones);

  int get sinLeer => _notificaciones.where((n) => !n.leida).length;

  // ── Mutadores básicos ──────────────────────────────────────────────────────
  void agregar(AppNotificacion n) {
    _notificaciones.insert(0, n);
    notifyListeners();
  }

  void marcarLeida(AppNotificacion n) {
    n.leida = true;
    notifyListeners();
  }

  void marcarTodasLeidas() {
    for (final n in _notificaciones) {
      n.leida = true;
    }
    notifyListeners();
  }

  void eliminar(AppNotificacion n) {
    _notificaciones.remove(n);
    notifyListeners();
  }

  // ── Helpers de dominio ─────────────────────────────────────────────────────

  /// Llama esto cuando un pedido se confirma exitosamente.
  void agregarPedidoConfirmado({
    required String orderCode,
    required double total,
    required String tipo,
  }) {
    final totalStr = total
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

    agregar(AppNotificacion(
      titulo: '✅ Pedido confirmado',
      cuerpo:
          'Código: $orderCode\nTotal: \$$totalStr COP — $tipo',
      icono: Icons.check_circle_rounded,
      color: Colors.green,
      fecha: DateTime.now(),
    ));
  }

  /// Llama esto cuando un medicamento queda con poco stock.
  void agregarAlertaBajoStock(String nombre, int stockNuevo) {
    agregar(AppNotificacion(
      titulo: '⚠️ Stock bajo: $nombre',
      cuerpo:
          '$nombre quedó con solo $stockNuevo unidades. El administrador fue notificado.',
      icono: Icons.warning_rounded,
      color: Colors.orange,
      fecha: DateTime.now(),
    ));
  }

  /// Llama esto cuando un medicamento se agota por completo.
  void agregarProductoAgotado(String nombre) {
    agregar(AppNotificacion(
      titulo: '🚫 Sin stock: $nombre',
      cuerpo: '$nombre se ha agotado. No está disponible para compra.',
      icono: Icons.remove_shopping_cart,
      color: Colors.red,
      fecha: DateTime.now(),
    ));
  }
}
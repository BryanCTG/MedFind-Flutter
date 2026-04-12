import 'package:flutter/material.dart';

// Modelo de notificación
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

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  // En una app real estas vendrían de Supabase o FCM
  final List<AppNotificacion> _notificaciones = [
    AppNotificacion(
      titulo: 'Medicamento disponible',
      cuerpo: 'Metformina 850mg ya está en stock. ¡Puedes agregarlo a tu carrito!',
      icono: Icons.check_circle_rounded,
      color: Colors.green,
      fecha: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotificacion(
      titulo: 'Stock agotado',
      cuerpo: 'Losartan 50mg se ha agotado en nuestra tienda. Te notificaremos cuando vuelva.',
      icono: Icons.warning_rounded,
      color: Colors.orange,
      fecha: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotificacion(
      titulo: 'Pedido en camino',
      cuerpo: 'Tu pedido #2024-001 está siendo preparado y saldrá pronto.',
      icono: Icons.delivery_dining,
      color: const Color(0xFF00BCD4),
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      leida: true,
    ),
    AppNotificacion(
      titulo: 'Recordatorio de medicación',
      cuerpo: 'Recuerda tomar tu Vitamina C. Tu salud es lo más importante.',
      icono: Icons.alarm,
      color: Colors.purple,
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      leida: true,
    ),
  ];

  void _marcarTodasLeidas() {
    setState(() {
      for (final n in _notificaciones) n.leida = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sinLeer = _notificaciones.where((n) => !n.leida).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notificaciones',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (sinLeer > 0)
              Text('$sinLeer sin leer',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF00BCD4))),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (sinLeer > 0)
            TextButton(
              onPressed: _marcarTodasLeidas,
              child: const Text('Marcar todo',
                  style: TextStyle(color: Color(0xFF00BCD4))),
            ),
        ],
      ),
      body: _notificaciones.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes notificaciones',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notificaciones.length,
              itemBuilder: (_, i) => _buildItem(_notificaciones[i]),
            ),
    );
  }

  Widget _buildItem(AppNotificacion n) {
    return Dismissible(
      key: Key(n.titulo + n.fecha.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => setState(() => _notificaciones.remove(n)),
      child: GestureDetector(
        onTap: () => setState(() => n.leida = true),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.leida ? Colors.white : n.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.leida ? Colors.grey.shade100 : n.color.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono con color
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: n.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.icono, color: n.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(n.titulo,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: n.leida ? Colors.black87 : Colors.black)),
                        if (!n.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: n.color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.cuerpo,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(_formatFecha(n.fecha),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime f) {
    final diff = DateTime.now().difference(f);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} día(s)';
  }
}
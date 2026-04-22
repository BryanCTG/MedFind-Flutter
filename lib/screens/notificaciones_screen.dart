import 'package:flutter/material.dart';
import '../services/notificacion_store.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _store = NotificacionStore();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Usamos una copia mutable para poder hacer Dismissible
    final lista = _store.notificaciones.toList();
    final sinLeer = _store.sinLeer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notificaciones',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sinLeer > 0)
              Text(
                '$sinLeer sin leer',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00BCD4),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (sinLeer > 0)
            TextButton(
              onPressed: _store.marcarTodasLeidas,
              child: const Text(
                'Marcar todo',
                style: TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
        ],
      ),
      body: lista.isEmpty
          ? const _PantallaVacia()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (_, i) => _buildItem(lista[i]),
            ),
    );
  }

  Widget _buildItem(AppNotificacion n) {
    return Dismissible(
      key: Key('${n.titulo}${n.fecha.millisecondsSinceEpoch}'),
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
      onDismissed: (_) => _store.eliminar(n),
      child: GestureDetector(
        onTap: () => _store.marcarLeida(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.leida ? Colors.white : n.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.leida
                  ? Colors.grey.shade100
                  : n.color.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono
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
                        Expanded(
                          child: Text(
                            n.titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: n.leida
                                  ? Colors.black87
                                  : Colors.black,
                            ),
                          ),
                        ),
                        if (!n.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: n.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.cuerpo,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatFecha(n.fecha),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
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
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} día(s)';
  }
}

class _PantallaVacia extends StatelessWidget {
  const _PantallaVacia();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
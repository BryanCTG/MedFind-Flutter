import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  const CarritoScreen({super.key, required this.carrito});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<Map<String, dynamic>> _items;
  bool _domicilio = false;
  bool _procesando = false;

  // Campos para domicilio
  final _direccionCtrl = TextEditingController();
  final _nombreReceptorCtrl = TextEditingController();

  // Precio del domicilio en COP
  static const double _precioDomicilio = 8000;

  @override
  void initState() {
    super.initState();
    // Copia para no mutar la lista original
    _items = widget.carrito.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // ── Cálculos en COP ────────────────────────────────────────────────────────
  double get _subtotal => _items.fold(
      0, (s, m) => s + ((m['precio'] as num) * (m['cantidad'] as int)));

  double get _costoEnvio => _domicilio ? _precioDomicilio : 0;
  double get _total => _subtotal + _costoEnvio;

  String _cop(double v) {
    final p = v.toInt();
    final f = p.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '\$$f COP';
  }

  // ── Confirmar pedido ───────────────────────────────────────────────────────
  Future<void> _confirmarPedido() async {
    if (_domicilio) {
      if (_direccionCtrl.text.isEmpty) {
        _snack('Por favor ingresa la dirección de entrega');
        return;
      }
      if (_nombreReceptorCtrl.text.isEmpty) {
        _snack('Por favor ingresa el nombre de quien recibe');
        return;
      }
    }

    setState(() => _procesando = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      final itemsData = _items
          .map((m) => {
                'id': m['id'],
                'nombre': m['nombre'],
                'precio': m['precio'],
                'cantidad': m['cantidad'],
              })
          .toList();

      await supabase.from('pedidos').insert({
        'usuario_id': userId,
        'items': itemsData,
        'metodo_entrega': _domicilio ? 'domicilio' : 'tienda',
        'direccion': _domicilio ? _direccionCtrl.text.trim() : null,
        'nombre_receptor': _domicilio ? _nombreReceptorCtrl.text.trim() : null,
        'costo_envio': _costoEnvio,
        'subtotal': _subtotal,
        'total': _total,
        'estado': 'pendiente',
      });

      if (mounted) {
        _mostrarExito();
      }
    } catch (e) {
      _snack('Error al procesar el pedido: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00BCD4), size: 72),
            const SizedBox(height: 16),
            const Text('¡Pedido confirmado!',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _domicilio
                  ? 'Tu pedido llegará a la dirección indicada'
                  : 'Puedes recoger tu pedido en tienda',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('Total: ${_cop(_total)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF00BCD4))),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // cierra dialog
                Navigator.pop(context); // vuelve al inicio
              },
              child: const Text('Ir al inicio'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Tu Carrito (${_items.length})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _items.isEmpty
          ? _buildCarritoVacio()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lista de productos
                        ..._items.map(_buildItemCard),
                        const SizedBox(height: 24),

                        // Método de entrega
                        const Text('Método de Entrega',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildOpcionEntrega(
                          icono: Icons.store,
                          titulo: 'Recogida en Tienda',
                          subtitulo: 'Sin costo adicional',
                          seleccionado: !_domicilio,
                          onTap: () => setState(() => _domicilio = false),
                        ),
                        const SizedBox(height: 8),
                        _buildOpcionEntrega(
                          icono: Icons.delivery_dining,
                          titulo: 'Domicilio',
                          subtitulo: 'Costo: ${_cop(_precioDomicilio)}',
                          seleccionado: _domicilio,
                          onTap: () => setState(() => _domicilio = true),
                        ),

                        // Formulario domicilio
                        if (_domicilio) ...[
                          const SizedBox(height: 16),
                          const Text('Datos de entrega',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nombreReceptorCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Nombre de quien recibe',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _direccionCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText:
                                  'Dirección completa (Calle, Barrio, Ciudad)',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Resumen de pago en COP
                        const Text('Resumen de Pago',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildFila('Subtotal', _cop(_subtotal)),
                        if (_domicilio)
                          _buildFila('Domicilio', _cop(_costoEnvio)),
                        const Divider(height: 24),
                        _buildFila('Total', _cop(_total), bold: true),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Botón confirmar pegado al fondo
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _procesando ? null : _confirmarPedido,
                      child: _procesando
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Confirmar y Pagar',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCarritoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Tu carrito está vacío',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Agrega medicamentos desde el catálogo',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver Catálogo'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_rounded,
                size: 28, color: Color(0xFF00BCD4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nombre'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(_cop((item['precio'] as num).toDouble()),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          // Controles cantidad
          Row(
            children: [
              _btnCantidad(
                  icon: Icons.remove,
                  onTap: () {
                    setState(() {
                      if (item['cantidad'] > 1) {
                        item['cantidad']--;
                      } else {
                        _items.remove(item);
                      }
                    });
                  }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item['cantidad']}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _btnCantidad(
                  icon: Icons.add,
                  filled: true,
                  onTap: () => setState(() => item['cantidad']++)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btnCantidad(
      {required IconData icon,
      required VoidCallback onTap,
      bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF00BCD4) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00BCD4)),
        ),
        child: Icon(icon,
            size: 16, color: filled ? Colors.white : const Color(0xFF00BCD4)),
      ),
    );
  }

  Widget _buildOpcionEntrega({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF00BCD4)
                : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icono,
                color: seleccionado
                    ? const Color(0xFF00BCD4)
                    : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: seleccionado
                              ? const Color(0xFF00BCD4)
                              : Colors.black)),
                  Text(subtitulo,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: seleccionado,
              activeColor: const Color(0xFF00BCD4),
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFila(String label, String valor, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(valor,
              style: style.copyWith(
                  color: bold ? const Color(0xFF00BCD4) : null)),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../main.dart';

class RecetaScreen extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onMedicamentosEncontrados;
  const RecetaScreen({super.key, required this.onMedicamentosEncontrados});

  @override
  State<RecetaScreen> createState() => _RecetaScreenState();
}

class _RecetaScreenState extends State<RecetaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  String _estado = 'listo'; // listo | analizando | resultado | error
  List<Map<String, dynamic>> _encontrados = [];
  List<String> _noEncontrados = [];
  String _mensajeError = '';

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  // Abre la cámara y envía la imagen al webhook de n8n
  Future<void> _tomarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1200);
    if (foto == null) return;

    setState(() => _estado = 'analizando');

    try {
      final bytes = await foto.readAsBytes();
      final base64Img = base64Encode(bytes);
      final userId = supabase.auth.currentUser?.id ?? 'anonimo';
      final webhookUrl = dotenv.env['N8N_WEBHOOK_URL'] ?? '';

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Img, 'user_id': userId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _encontrados = List<Map<String, dynamic>>.from(
              data['medicamentos_disponibles'] ?? []);
          _noEncontrados =
              List<String>.from(data['medicamentos_no_disponibles'] ?? []);
          _estado = 'resultado';
        });
      } else {
        setState(() {
          _mensajeError = 'Error del servidor: ${response.statusCode}';
          _estado = 'error';
        });
      }
    } catch (e) {
      setState(() {
        _mensajeError = 'No se pudo conectar con el servidor';
        _estado = 'error';
      });
    }
  }

  void _agregarTodosAlCarrito() {
    widget.onMedicamentosEncontrados(_encontrados);
    Navigator.pop(context);
    ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Analizar Receta',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildContenido(),
      ),
    );
  }

  Widget _buildContenido() {
    switch (_estado) {
      case 'analizando':
        return _buildAnalizando();
      case 'resultado':
        return _buildResultado();
      case 'error':
        return _buildError();
      default:
        return _buildListo();
    }
  }

  // Pantalla inicial: botones para tomar foto o subir desde galería
  Widget _buildListo() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_rounded,
                size: 64, color: Color(0xFF00BCD4)),
          ),
          const SizedBox(height: 24),
          const Text('Escanear Receta Médica',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Toma una foto de tu receta y nuestra IA identificará los medicamentos automáticamente',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => _tomarFoto(ImageSource.camera),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Seleccionar de Galería',
                  style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF00BCD4)),
                foregroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => _tomarFoto(ImageSource.gallery),
            ),
          ),
        ],
      ),
    );
  }

  // Pantalla de carga mientras n8n procesa
  Widget _buildAnalizando() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _spinCtrl,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFFB2EBF2), Color(0xFF00BCD4)],
                  ),
                ),
                child: const Center(
                  child: CircleAvatar(radius: 46, backgroundColor: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Analizando receta...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'La IA está identificando los medicamentos\ny buscando disponibilidad en stock',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // Pantalla con los resultados del análisis
  Widget _buildResultado() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Análisis completado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Se encontraron ${_encontrados.length} medicamentos disponibles',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // Medicamentos encontrados
          if (_encontrados.isNotEmpty) ...[
            const Text('Disponibles en stock',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ..._encontrados.map((m) => _buildMedResultado(m, true)),
          ],

          // Medicamentos no encontrados
          if (_noEncontrados.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('No disponibles',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.red)),
            const SizedBox(height: 10),
            ..._noEncontrados.map((n) => _buildNoDisponible(n)),
          ],

          const SizedBox(height: 28),
          if (_encontrados.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _agregarTodosAlCarrito,
                child: Text(
                  'Añadir ${_encontrados.length} al carrito',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF00BCD4)),
                foregroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => setState(() => _estado = 'listo'),
              child: const Text('Escanear otra receta'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedResultado(Map<String, dynamic> med, bool disponible) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['nombre'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_formatCOP(med['precio']),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDisponible(String nombre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(nombre,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Ocurrió un error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_mensajeError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => setState(() => _estado = 'listo'),
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCOP(dynamic precio) {
    if (precio == null) return '\$0 COP';
    final p = (precio as num).toInt();
    final f = p.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '\$$f COP';
  }
}
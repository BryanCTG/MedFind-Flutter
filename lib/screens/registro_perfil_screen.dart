import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'inicio_screen.dart';

class RegistroPerfilScreen extends StatefulWidget {
  final bool esEdicion; // true = editar perfil existente
  const RegistroPerfilScreen({super.key, this.esEdicion = false});

  @override
  State<RegistroPerfilScreen> createState() => _RegistroPerfilScreenState();
}

class _RegistroPerfilScreenState extends State<RegistroPerfilScreen> {
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _nuevaAlergiaCtr = TextEditingController();
  final _nuevaCondicionCtr = TextEditingController();

  List<String> _alergias = [];
  List<String> _condiciones = [];
  bool _isLoading = false;

  // Condiciones predefinidas como chips rápidos
  final List<String> _condicionesPredefinidas = [
    'Diabetes', 'Hipertensión', 'Asma', 'Colesterol alto',
    'Artritis', 'Tiroides', 'Anemia', 'Migraña',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) _cargarPerfilExistente();
  }

  // Carga el perfil existente desde Supabase para edición
  Future<void> _cargarPerfilExistente() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();
      setState(() {
        _nombreController.text = data['nombre'] ?? '';
        _edadController.text = data['edad']?.toString() ?? '';
        _alergias = List<String>.from(data['alergias'] ?? []);
        _condiciones = List<String>.from(data['condiciones'] ?? []);
      });
    } catch (_) {}
  }

  // Agrega una alergia a la lista
  void _agregarAlergia(String valor) {
    final v = valor.trim();
    if (v.isNotEmpty && !_alergias.contains(v)) {
      setState(() => _alergias.add(v));
    }
    _nuevaAlergiaCtr.clear();
  }

  // Agrega o quita una condición
  void _toggleCondicion(String condicion) {
    setState(() {
      if (_condiciones.contains(condicion)) {
        _condiciones.remove(condicion);
      } else {
        _condiciones.add(condicion);
      }
    });
  }

  // Guarda en Supabase usando upsert (crea o actualiza)
  Future<void> _guardarPerfil() async {
    if (_nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
if (userId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Debes iniciar sesión primero'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
      // upsert = insert si no existe, update si ya existe
      await supabase.from('perfiles').upsert({
        'id': userId,
        'nombre': _nombreController.text.trim(),
        'edad': int.tryParse(_edadController.text) ?? 0,
        'alergias': _alergias,
        'condiciones': _condiciones,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil guardado exitosamente!'),
            backgroundColor: Color(0xFF00BCD4),
          ),
        );
        if (widget.esEdicion) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InicioScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FBFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.esEdicion ? 'Editar Perfil' : 'Ficha Médica',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: widget.esEdicion
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF80DEEA),
                    child: const Icon(Icons.person, size: 56, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BCD4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            _label('Nombre completo *'),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(hintText: 'Tu nombre'),
            ),
            const SizedBox(height: 14),

            // Edad
            _label('Edad'),
            TextField(
              controller: _edadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Tu edad'),
            ),
            const SizedBox(height: 22),

            // Alergias
            _label('Alergias conocidas'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevaAlergiaCtr,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Penicilina, Mariscos...',
                    ),
                    onSubmitted: _agregarAlergia,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _agregarAlergia(_nuevaAlergiaCtr.text),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Lista de alergias agregadas
            if (_alergias.isNotEmpty)
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _alergias.map((a) => Chip(
                  label: Text(a),
                  backgroundColor: Colors.red.shade50,
                  deleteIconColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade200),
                  onDeleted: () => setState(() => _alergias.remove(a)),
                )).toList(),
              ),
            const SizedBox(height: 22),

            // Condiciones crónicas
            _label('Condiciones crónicas'),
            const SizedBox(height: 8),
            // Chips predefinidos (toca para seleccionar/deseleccionar)
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _condicionesPredefinidas.map((c) {
                final sel = _condiciones.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) => _toggleCondicion(c),
                  selectedColor: const Color(0xFF00BCD4).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF00BCD4),
                  side: BorderSide(
                    color: sel ? const Color(0xFF00BCD4) : Colors.grey.shade300,
                  ),
                  labelStyle: TextStyle(
                    color: sel ? const Color(0xFF00BCD4) : Colors.black87,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Agregar condición personalizada
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevaCondicionCtr,
                    decoration: const InputDecoration(
                      hintText: 'Agregar otra condición...',
                    ),
                    onSubmitted: (v) {
                      _toggleCondicion(v.trim());
                      _nuevaCondicionCtr.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _toggleCondicion(_nuevaCondicionCtr.text.trim());
                    _nuevaCondicionCtr.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _guardarPerfil,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.esEdicion ? 'Guardar Cambios' : 'Guardar Perfil',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      );
}
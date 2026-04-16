import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'carrito_screen.dart';
import 'notificaciones_screen.dart';
import 'registro_perfil_screen.dart';
import 'login_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _tabIndex = 0;
  List<Map<String, dynamic>> _medicamentos = [];
  List<Map<String, dynamic>> _recomendados = [];
  String _nombreUsuario = 'Usuario';
  List<String> _condiciones = [];
  bool _cargando = true;
  final _busquedaCtrl = TextEditingController();
  int _notificacionesSinLeer = 2;

  final List<Map<String, dynamic>> _carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([_cargarPerfil(), _cargarMedicamentos()]);
    setState(() => _cargando = false);
  }

  Future<void> _cargarPerfil() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await supabase
          .from('perfiles')
          .select('nombre, condiciones')
          .eq('id', userId)
          .single();
      _nombreUsuario = data['nombre'] ?? 'Usuario';
      _condiciones = List<String>.from(data['condiciones'] ?? []);
    } catch (_) {}
  }

  Future<void> _cargarMedicamentos({String? busqueda}) async {
    try {
      var query = supabase.from('medicamentos').select();

      if (busqueda != null && busqueda.isNotEmpty) {
        query = query.ilike('nombre', '%$busqueda%');
      }

      final data = await query.order('nombre').limit(20);
      setState(() => _medicamentos = List<Map<String, dynamic>>.from(data));

      if (_condiciones.isNotEmpty) {
        final cond = _condiciones.first.toLowerCase();
        setState(() {
          _recomendados = _medicamentos
              .where((m) =>
                  (m['categoria'] ?? '').toLowerCase().contains(cond) ||
                  (m['nombre'] ?? '').toLowerCase().contains(cond))
              .toList();
        });
      }
    } catch (_) {}
  }

  void _agregarAlCarrito(Map<String, dynamic> med) {
    final existe = _carrito.indexWhere((m) => m['id'] == med['id']);
    if (existe >= 0) {
      setState(() => _carrito[existe]['cantidad']++);
    } else {
      setState(() => _carrito.add({...med, 'cantidad': 1}));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med['nombre']} añadido al carrito'),
        backgroundColor: const Color(0xFF00BCD4),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildBusqueda()),
                  if (_recomendados.isNotEmpty)
                    SliverToBoxAdapter(child: _buildRecomendados()),
                  SliverToBoxAdapter(child: _buildTodosLosMedicamentos()),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MedFind',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BCD4))),
              Text('Hola, $_nombreUsuario!',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 28),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificacionesScreen()),
                    ),
                  ),
                  if (_notificacionesSinLeer > 0)
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '$_notificacionesSinLeer',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              PopupMenuButton(
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF80DEEA),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'perfil',
                    child: Row(children: [
                      Icon(Icons.edit), SizedBox(width: 8),
                      Text('Editar perfil')
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'salir',
                    child: Row(children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cerrar sesión',
                          style: TextStyle(color: Colors.red))
                    ]),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'perfil') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const RegistroPerfilScreen(esEdicion: true)),
                    );
                  } else if (v == 'salir') {
                    _cerrarSesion();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _busquedaCtrl,
        onChanged: (v) => _cargarMedicamentos(busqueda: v),
        decoration: InputDecoration(
          hintText: 'Buscar medicamentos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _busquedaCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    _cargarMedicamentos();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecomendados() {
    final label = _condiciones.isNotEmpty ? _condiciones.first : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text.rich(TextSpan(
            text: 'Recomendado para ti ',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: '($label)',
                style: const TextStyle(
                    color: Color(0xFF00BCD4), fontWeight: FontWeight.w500),
              )
            ],
          )),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recomendados.length,
            itemBuilder: (_, i) => _buildMedCard(_recomendados[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTodosLosMedicamentos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text('Todos los medicamentos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _medicamentos.length,
          itemBuilder: (_, i) => _buildMedCardGrid(_medicamentos[i]),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMedCard(Map<String, dynamic> med) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medication_rounded,
                  size: 40, color: Color(0xFF00BCD4)),
            ),
          ),
          const SizedBox(height: 8),
          Text(med['nombre'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(_formatCOP(med['precio']),
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00BCD4)),
                foregroundColor: const Color(0xFF00BCD4),
                padding: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _agregarAlCarrito(med),
              child: const Text('Añadir', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedCardGrid(Map<String, dynamic> med) {
    final stock = med['stock'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_rounded,
                size: 36, color: Color(0xFF00BCD4)),
          ),
          const SizedBox(height: 8),
          Text(med['nombre'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(_formatCOP(med['precio']),
              style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stock > 0 ? 'Disponible' : 'Agotado',
              style: TextStyle(
                  color: stock > 0 ? Colors.green : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor:
                    stock > 0 ? const Color(0xFF00BCD4) : Colors.grey,
              ),
              onPressed: stock > 0 ? () => _agregarAlCarrito(med) : null,
              child: const Text('Añadir', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final cantCarrito =
        _carrito.fold<int>(0, (s, m) => s + (m['cantidad'] as int));
    return BottomNavigationBar(
      currentIndex: _tabIndex,
      selectedItemColor: const Color(0xFF00BCD4),
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CarritoScreen(carrito: _carrito),
            ),
          );
        } else {
          setState(() => _tabIndex = i);
        }
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
        BottomNavigationBarItem(
          label: 'Carrito',
          icon: Badge(
            isLabelVisible: cantCarrito > 0,
            label: Text('$cantCarrito'),
            child: const Icon(Icons.shopping_cart),
          ),
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Perfil'),
      ],
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
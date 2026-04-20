import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get _orderUrl =>
      dotenv.env['N8N_ORDER_WEBHOOK_URL'] ??
      'https://briayanbeltranm.app.n8n.cloud/webhook-test/medfind-order';

  static String get _lowStockUrl =>
      dotenv.env['N8N_LOW_STOCK_WEBHOOK_URL'] ?? 'https://briayanbeltranm.app.n8n.cloud/webhook-test/medfind-low-stock';

  // ── Envío de pedido  ───────
  static Future<String?> enviarPedido({
    required String userName,
    required double total,
    required String type,
    required List items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_orderUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'total': total,
          'type': type,
          'items': items,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orderCode']?.toString();
      }
      return null;
    } catch (e) {
      print('ERROR enviarPedido: $e');
      return null;
    }
  }

  // ── Alerta de bajo stock → n8n ────────────
  // medicamentosAgotados: lista de {id, nombre, stock_nuevo}
  static Future<void> alertarBajoStock({
    required List<Map<String, dynamic>> medicamentosAgotados,
  }) async {
    final url = _lowStockUrl;
    if (url.isEmpty) {
      print('N8N_LOW_STOCK_WEBHOOK_URL no configurado en .env');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'medicamentos': medicamentosAgotados,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      print('Low stock alert → ${response.statusCode}');
    } catch (e) {
      // Alerta no crítica — no interrumpe el flujo del pedido
      print('ERROR alertarBajoStock: $e');
    }
  }
}


































// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   static const String url =
// "https://briayanbeltranm.app.n8n.cloud/webhook-test/medfind-order";

//   static Future<String?> enviarPedido({
//   required String userName,
//   required double total,
//   required String type,
//   required List items , 
// }) async {
//   try {
//     final response = await http.post(
//       Uri.parse(url),
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "userName": userName,
//         "total": total,
//         "type": type,
//         "items": items,
//       }),
//     );

//     print("STATUS: ${response.statusCode}");
//     print("BODY: ${response.body}");

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);

//       if (data != null && data['orderCode'] != null) {
//         return data['orderCode'].toString();
//       } else {
//         print("ERROR: orderCode no viene en response");
//         return null;
//       }
//     } else {
//       print("ERROR HTTP");
//       return null;
//     }
//   } catch (e) {
//     print("ERROR API: $e");
//     return null;
//   }
// }}
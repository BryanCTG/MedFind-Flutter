import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // URLs leídas del .env. Si no existe la variable, usa la URL de producción.
  static String get _orderUrl =>
      dotenv.env['N8N_ORDER_WEBHOOK_URL'] ??
      'https://briayanbeltranm.app.n8n.cloud/webhook/medfind-order';

  static String get _lowStockUrl =>
      dotenv.env['N8N_LOW_STOCK_WEBHOOK_URL'] ??
      'https://briayanbeltranm.app.n8n.cloud/webhook/medfind-low-stock';

  /// Envía el pedido al webhook de n8n y retorna el código de pedido.
  static Future<String?> enviarPedido({
    required String userName,
    required double total,
    required String type,
    required List items,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_orderUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userName': userName,
              'total': total,
              'type': type,
              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orderCode']?.toString();
      }
      return null;
    } catch (e) {
      // No lanzamos para no interrumpir el flujo del pedido
      debugPrint('ERROR enviarPedido: $e');
      return null;
    }
  }

  /// Alerta al administrador vía n8n cuando un medicamento tiene poco stock.
  /// [medicamentosAgotados] — lista de {id, nombre, stock_nuevo}
  static Future<void> alertarBajoStock({
    required List<Map<String, dynamic>> medicamentosAgotados,
  }) async {
    try {
      await http
          .post(
            Uri.parse(_lowStockUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'medicamentos': medicamentosAgotados,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      // Alerta no crítica: no interrumpe el flujo del pedido
      debugPrint('ERROR alertarBajoStock: $e');
    }
  }
}
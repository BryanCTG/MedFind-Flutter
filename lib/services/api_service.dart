import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String url =
"https://briayanbeltranm.app.n8n.cloud/webhook-test/medfind-order";

  static Future<String?> enviarPedido({
  required String userName,
  required double total,
  required String type,
  required List items , 
}) async {
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userName": userName,
        "total": total,
        "type": type,
        "items": items,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data != null && data['orderCode'] != null) {
        return data['orderCode'].toString();
      } else {
        print("ERROR: orderCode no viene en response");
        return null;
      }
    } else {
      print("ERROR HTTP");
      return null;
    }
  } catch (e) {
    print("ERROR API: $e");
    return null;
  }
}}
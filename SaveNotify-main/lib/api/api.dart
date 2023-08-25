import 'dart:convert';

import 'package:http/http.dart' as http;

class Api {
  Future<void> sendNoty(String token, String celular, String fecha,
      String monto, String nombre, String deviceId) async {
    var response = await http.post(
        Uri.parse(
            'https://m0uez7vsl1.execute-api.us-east-1.amazonaws.com/test'),
        body: json.encode({
          "celular": celular,
          "fecha_hora": fecha,
          "monto": monto,
          "nombre_depositante": nombre,
          "id_equipo": deviceId
        }),
        headers: {
          'Content-Type': 'application/json',
          'charset': 'utf-8',
          'Authorization': token,
        });
    if (response.statusCode == 200) {
      print(response.body);
    } else {
      print(response.body);
      print('Un error bro :c');
    }
  }
}

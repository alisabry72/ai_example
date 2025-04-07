import 'dart:convert';

import 'package:http/http.dart' as http;

class IntentPredictionService {
  static const String baseUrl =
      'http://10.0.2.2:8000'; // Replace with your server IP

  Future<Map<String, dynamic>> predictIntent(String text, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        // Decode the response body as UTF-8
        final decodedResponse = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedResponse);
        print(jsonData); // Should now show readable Arabic
        return jsonData;
      } else {
        throw Exception('Failed to predict intent: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting intent: $e');
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RemoteRequest {
  final String baseUrl = 'http://192.168.1.4:5000';
  Future<String> predictIntent(String userInput) async {
    debugPrint("userInput : $userInput");
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": userInput}),
    );
    print("response is ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(
          "Predicted Tag: ${data['tag']} (Confidence: ${data['confidence']})");
      print("Response: ${data['response']}");
      print("Processed Input: ${data['processed_input']}");
      print("Threshold Applied: ${data['threshold_applied']}");
      return data['response'];
    } else {
      print("Error: ${response.body}");
      return "error";
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

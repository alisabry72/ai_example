import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RemoteRequest {
  Future<String> predictIntent(String userInput) async {
    final uri = Uri.parse("https://chatbot-bpvyejnpwa-uc.a.run.app/predict");
    debugPrint("userInput : $userInput");
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": userInput}),
    );
    print("response is ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(
          "Predicted Intent: ${data['intent']} (Confidence: ${data['confidence']})");
      return data['intent'];
    } else {
      print("Error: ${response.body}");
      return "error";
    }
  }
}

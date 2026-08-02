import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AIService {
  // TODO: Change this to your computer's IP when testing on a real phone.
  // Example: http://192.168.1.5:5000
 static const String baseUrl = "http://127.0.0.1:5001";

  Future<String> recognizeEquation(File imageFile) async {

    print("====== AI SERVICE ======");
    print(baseUrl);
    print("$baseUrl/recognize");
    print(imageFile.path);

    final uri = Uri.parse("$baseUrl/recognize");

    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        "image",
        imageFile.path,
      ),
    );

    print("Sending image to AI...");
    print(imageFile.path);
    print(uri);

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        return data["latex"];
      } else {
        throw Exception(data["error"]);
      }
    } else {
      throw Exception("Failed to connect to AI server.");
    }
  }
}
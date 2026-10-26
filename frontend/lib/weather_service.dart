
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://127.0.0.1:3000';
    }
  }

  Future<Map<String, dynamic>> getWeather(String city) async {
    final trimmedCity = city.trim();
    final queryCity = trimmedCity.contains(',') ? trimmedCity : '$trimmedCity, India';
    final uri = Uri.parse('$baseUrl/api/weather').replace(
      queryParameters: {'city': queryCity},
    );

    final response = await http
    .get(uri)
    .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to load weather');
    }

    return data as Map<String, dynamic>;
  }
  Future<Map<String, dynamic>> getWeatherByLocation(
  double latitude,
  double longitude,
) async {
  final uri = Uri.parse('$baseUrl/api/weather').replace(
    queryParameters: {
      'city': '$latitude,$longitude',
    },
  );

  final response = await http
      .get(uri)
      .timeout(const Duration(seconds: 20));

  final data = jsonDecode(response.body);

  if (response.statusCode != 200) {
    throw Exception(data['error'] ?? 'Failed to load weather');
  }

  return data as Map<String, dynamic>;
}
}

import 'dart:convert';
import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> searchLocationService(String query) async {
  final token = dotenv.env['MAP_BOX_ACCESS']!;
  final encodedQuery = Uri.encodeComponent(query);
  final url =
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$token&limit=5';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    logger.e('failed to fetch location: Status ${response.statusCode}');
    throw Exception('failed to fetch location: Status ${response.statusCode}');
  }

  final data = json.decode(response.body);
  final features = data['features'] as List;

  return features.map((f) {
    logger.i(
      'success to fetch location: Status ${response.statusCode} - ${f['place_name']}',
    );
    return {
      'name': f['place_name'] as String,
      'longitude': f['center'][0].toString(),
      'latitude': f['center'][1].toString(),
    };
  }).toList();
}

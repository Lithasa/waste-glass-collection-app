import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip_model.dart';
import '../models/collection_local_model.dart';

class ApiService {
  // During USB testing, use adb reverse tcp:5057 tcp:5057.
  
  static const String baseUrl = 'https://waste-glass-api.onrender.com';

  Future<TripModel> getTodayTrip() async {
    final response = await http.get(Uri.parse('$baseUrl/api/trips/today'));

    if (response.statusCode == 200) {
      return TripModel.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load today trip: ${response.body}');
  }

  Future<Map<String, dynamic>> resetDemoTrip() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/trips/reset-demo'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to reset demo trip: ${response.body}');
  }

  Future<Map<String, dynamic>> submitCollection({
    required String supplierCode,
    required double clearKg,
    required double colouredKg,
    required String condition,
    required String localRecordId,
    required String collectedAt,
  }) async {
    final body = {
      'supplierCode': supplierCode,
      'clearKg': clearKg,
      'colouredKg': colouredKg,
      'condition': condition,
      'localRecordId': localRecordId,
      'collectedAt': collectedAt,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/collections'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decoded;
    }

    throw Exception(decoded['message'] ?? 'Collection submission failed');
  }

  Future<Map<String, dynamic>> getTodayReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/trips/today/report'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load report: ${response.body}');
  }

  Future<Map<String, dynamic>> syncCollections(
    List<CollectionLocalModel> records,
  ) async {
    final body = {
      'records': records.map((record) {
        return {
          'supplierCode': record.supplierCode,
          'clearKg': record.clearKg,
          'colouredKg': record.colouredKg,
          'condition': record.condition,
          'localRecordId': record.localRecordId,
          'collectedAt': record.collectedAt,
        };
      }).toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/collections/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decoded;
    }

    throw Exception(decoded['message'] ?? 'Sync failed');
  }
}

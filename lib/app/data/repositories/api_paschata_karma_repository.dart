import 'package:get/get.dart';

import '../models/assessment/paschata_karma_model.dart';
import '../services/api_service.dart';

/// Repository for Paschata Karma API integration.
///
/// Communicates with:
/// - `GET /paschata-karma/:patientId`
/// - `PUT /paschata-karma/:patientId`
///
/// Uses [ApiService] for automatic JWT authentication and network handling.
class ApiPaschataKarmaRepository {
  final ApiService _apiService;

  ApiPaschataKarmaRepository({ApiService? apiService})
      : _apiService = apiService ??
            (Get.isRegistered<ApiService>()
                ? Get.find<ApiService>()
                : ApiService());

  /// Fetches existing Paschata Karma assessment for [patientId].
  ///
  /// Returns `null` if no record exists yet (HTTP 404).
  /// Throws [Exception] on server (5xx) or network errors.
  Future<PaschataKarmaModel?> getPaschataKarma(String patientId) async {
    final response = await _apiService.get('/paschata-karma/$patientId');

    if (response.statusCode == 404) {
      return null;
    }

    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(msg);
    }

    final body = response.body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return PaschataKarmaModel.fromJson(data);
      }
      return PaschataKarmaModel.fromJson(body);
    }

    return null;
  }

  /// Persists or updates the Paschata Karma assessment for [patientId].
  ///
  /// [niruhaVyapada] and [anuvasanaVyapada] can be either the UI string labels
  /// (e.g. "Ayoga (under-action)", "Vatavruta Sneha") or backend enum values.
  /// They will be automatically coerced to the backend camelCase enum format.
  ///
  /// Throws [Exception] on server (5xx), validation (4xx), or network errors.
  Future<PaschataKarmaModel> savePaschataKarma(
    String patientId, {
    required String niruhaVyapada,
    required String anuvasanaVyapada,
  }) async {
    final niruhaEnum = PaschataKarmaModel.niruhaLabelToEnum(niruhaVyapada);
    final anuvasanaEnum =
        PaschataKarmaModel.anuvasanaLabelToEnum(anuvasanaVyapada);

    final payload = {
      'vyapadaAndManagement': {
        'niruhaVyapada': niruhaEnum,
        'anuvasanaVyapada': anuvasanaEnum,
      },
    };

    final response =
        await _apiService.put('/paschata-karma/$patientId', payload);

    if (!response.isOk) {
      final msg = ApiService.extractErrorMessage(response);
      throw Exception(msg);
    }

    final body = response.body;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return PaschataKarmaModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    return PaschataKarmaModel(
      patientId: patientId,
      niruhaVyapada: niruhaEnum,
      anuvasanaVyapada: anuvasanaEnum,
    );
  }
}

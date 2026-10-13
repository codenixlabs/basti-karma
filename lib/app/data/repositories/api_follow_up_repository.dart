import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/patient/follow_up_model.dart';

class ApiFollowUpRepository {
  final ApiService _apiService;

  ApiFollowUpRepository({ApiService? apiService})
    : _apiService = apiService ?? (Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService());

  Future<FollowUpModel?> getFollowUp(String patientId) async {
    final response = await _apiService.get('/follow-up/$patientId');

    if (response.hasError) {
      if (response.statusCode == 404) {
        return null; // Not found is fine, just means no notes yet
      }
      throw Exception('Failed to get follow-up data: ${response.statusText}');
    }

    if (response.body != null && response.body['success'] == true) {
      final data = response.body['data'];
      if (data == null) return null;
      return FollowUpModel.fromJson(data);
    }
    
    return null;
  }

  Future<FollowUpModel> saveFollowUp(String patientId, String notes) async {
    final payload = {'notes': notes};
    // Using PUT or POST based on the documentation (it says POST OR PUT /api/follow-up/:patientId)
    // Here we'll try POST first, as it usually handles upsert
    final response = await _apiService.post('/follow-up/$patientId', payload);

    if (response.hasError) {
      throw Exception('Failed to save follow-up data: ${response.statusText}');
    }

    if (response.body != null && response.body['success'] == true) {
      return FollowUpModel.fromJson(response.body['data']);
    }

    throw Exception('Failed to save follow-up data: unexpected response format');
  }
}

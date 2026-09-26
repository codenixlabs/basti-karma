import 'dart:io';

import 'package:get/get.dart';

import '../models/resource/resource_model.dart';
import '../services/api_service.dart';

abstract class IResourceRepository {
  Future<List<ResourceModel>> getResources();
  Future<ResourceModel> uploadResource({
    required String title,
    String? description,
    required File file,
  });
}

class ResourceRepository implements IResourceRepository {
  final ApiService _apiService;

  ResourceRepository({ApiService? apiService})
      : _apiService = apiService ??
            (Get.isRegistered<ApiService>()
                ? Get.find<ApiService>()
                : ApiService());

  @override
  Future<List<ResourceModel>> getResources() async {
    try {
      final response = await _apiService.get('/resources');
      if (response.isOk && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        if (body['success'] == true && body['data'] is List) {
          final list = body['data'] as List;
          return list
              .whereType<Map>()
              .map((e) => ResourceModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final error = ApiService.extractErrorMessage(response);
      throw Exception(error);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  @override
  Future<ResourceModel> uploadResource({
    required String title,
    String? description,
    required File file,
  }) async {
    try {
      final fileName = file.path.split(RegExp(r'[/\\]')).last;
      final form = FormData({
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'file': MultipartFile(
          file,
          filename: fileName,
          contentType: 'application/pdf',
        ),
      });

      final response = await _apiService.post('/resources', form);
      if (response.isOk && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        if (body['success'] == true && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          return ResourceModel.fromJson(data);
        }
      }
      final error = ApiService.extractErrorMessage(response);
      throw Exception(error);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }
}

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/data/models/resource/resource_model.dart';
import '../../../app/data/repositories/resource_repository.dart';
import '../../../app/shared/utils/custom_snackbar.dart';

class ResourceController extends GetxController {
  final IResourceRepository _repository;

  ResourceController({IResourceRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<ResourceRepository>()
                ? Get.find<ResourceRepository>()
                : ResourceRepository());

  final resources = <ResourceModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchResources();
  }

  Future<void> fetchResources() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final list = await _repository.getResources();
      resources.value = list;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openResource(ResourceModel resource) async {
    final urlString = resource.fileUrl.trim();
    if (urlString.isEmpty) {
      CustomSnackBar.showError('Resource document URL is not available.');
      return;
    }

    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      CustomSnackBar.showError('Invalid document URL.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        CustomSnackBar.showError('Could not open document link.');
      }
    } catch (e) {
      CustomSnackBar.showError('Failed to open document: $e');
    }
  }
}

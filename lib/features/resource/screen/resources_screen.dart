import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/core/theme/app_theme.dart';
import '../controller/resource_controller.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ResourceController());

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryGreen, Color(0xFF3D7A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resources',
                  style: AppTextStyles.pageTitle,
                ),
                SizedBox(height: 4),
                Text(
                  'Clinical guidelines & references',
                  style: AppTextStyles.pageSubtitle,
                ),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryGreen),
                      SizedBox(height: 16),
                      Text(
                        'Loading clinical resources...',
                        style: TextStyle(
                          color: AppColors.textDarkGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (ctrl.errorMessage.value != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: AppColors.errorRed,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ctrl.errorMessage.value!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: ctrl.fetchResources,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (ctrl.resources.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: ctrl.fetchResources,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen
                                        .withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_outlined,
                                    color: AppColors.primaryGreen,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No Resources Available',
                                  style: TextStyle(
                                    color: AppColors.textDarkGreen,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Clinical guidelines and reference documents will appear here once published.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.darkGrey,
                                    fontSize: 13.5,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: ctrl.fetchResources,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  itemCount: ctrl.resources.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final res = ctrl.resources[index];
                    return Card(
                      elevation: 2,
                      shadowColor:
                          AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color:
                              AppColors.primaryGreen.withValues(alpha: 0.15),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => ctrl.openResource(res),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD32F2F)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Color(0xFFD32F2F),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.title,
                                      style: const TextStyle(
                                        color: AppColors.textDarkGreen,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (res.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        res.description,
                                        style: const TextStyle(
                                          color: AppColors.darkGrey,
                                          fontSize: 13,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            res.fileType.toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'Open PDF',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 14,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
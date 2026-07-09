import 'package:flutter/material.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';


class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  static const _resources = [
    {
      'icon': Icons.menu_book_outlined,
      'title': 'Panchakarma Guide',
      'tag': 'Treatment Protocols',
      'subtitle': 'Complete guide to Panchakarma procedures and protocols',
      'iconColor': 0xFF2F5D3A,
    },
    {
      'icon': Icons.description_outlined,
      'title': 'Treatment Instructions',
      'tag': 'Clinical Guidelines',
      'subtitle': 'Step-by-step instructions for various Ayurvedic treatments',
      'iconColor': 0xFF2F5D3A,
    },
    {
      'icon': Icons.warning_amber_outlined,
      'title': 'Vyapada Management',
      'tag': 'Emergency Protocols',
      'subtitle': 'Managing complications and adverse effects',
      'iconColor': 0xFFE74C3C,
    },
    {
      'icon': Icons.restaurant_outlined,
      'title': 'Diet Guidelines',
      'tag': 'Nutrition',
      'subtitle': 'Dietary recommendations for Panchakarma patients',
      'iconColor': 0xFF555555,
    },
    // {
    //   'icon': Icons.eco_outlined,
    //   'title': 'Herbal Medicine Reference',
    //   'tag': 'Pharmacology',
    //   'subtitle': 'Common herbs and their therapeutic applications',
    //   'iconColor': 0xFF2F5D3A,
    // },
  ];

  static const _quickRef = [
    {'label': 'Snehapana Duration:', 'value': '3-7 days'},
    {'label': 'Virechana Day:', 'value': 'After Snigdhata'},
    {'label': 'Follow-up Required:', 'value': 'Every 3 days'},
  ];

  @override
  Widget build(BuildContext context) {
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  // Resource cards
                  ..._resources.map(
                        (r) => _ResourceCard(
                      icon: r['icon'] as IconData,
                      title: r['title'] as String,
                      tag: r['tag'] as String,
                      subtitle: r['subtitle'] as String,
                      iconColor: Color(r['iconColor'] as int),
                      onTap: () {},
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Quick Reference card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGreen, Color(0xFF3D7A4F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Reference',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._quickRef.map(
                              (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['label']!,
                                  style: AppTextStyles.pageSubtitle,
                                ),
                                Text(
                                  item['value']!,
                                  style: AppTextStyles.stepPercent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Educational Resources info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌿', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Educational Resources',
                                style: AppTextStyles.profileSectionTitle,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'These resources are provided as clinical references based on classical Ayurvedic texts and modern research. Always adapt treatments to individual patient needs and conditions.',
                                style: TextStyle(
                                  color: AppColors.darkGrey,
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tag;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.profileSectionTitle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.darkGrey,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
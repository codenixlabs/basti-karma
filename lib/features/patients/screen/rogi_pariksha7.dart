import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/shared/widgets/app_dropdown.dart';
import '../controller/add_patient_controller.dart';
import '../widgets/form_widget.dart';
import '../widgets/sticky_nav.dart';

class Step7RogiPariksha extends StatelessWidget {
  const Step7RogiPariksha({super.key});

  static List<BottomSheetOption<String>> get _qualityOptions => [
    BottomSheetOption(
      value: 'Pravara (Excellent)',
      label: 'Pravara (Excellent)',
    ),
    BottomSheetOption(
      value: 'Madhyama (Moderate)',
      label: 'Madhyama (Moderate)',
    ),
    BottomSheetOption(value: 'Avara (Poor)', label: 'Avara (Poor)'),
  ];

  static List<BottomSheetOption<String>> get _shaktiOptions => [
    BottomSheetOption(value: 'Pravara', label: 'Pravara'),
    BottomSheetOption(value: 'Madhyama', label: 'Madhyama'),
    BottomSheetOption(value: 'Avara', label: 'Avara'),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddPatientController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // FIX: Was missing padding — inconsistent with all other steps.
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
              child: FormSectionCard(
                title: 'Rogi Pariksha',
                icon: Icons.spa_outlined,
                children: [
                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Prakriti',
                      hint: 'Select Prakriti',
                      value: ctrl.prakriti.value,
                      onChanged: (v) => ctrl.prakriti.value = v,
                      options: [
                        BottomSheetOption(value: 'Vata', label: 'Vata'),
                        BottomSheetOption(value: 'Pitta', label: 'Pitta'),
                        BottomSheetOption(value: 'Kapha', label: 'Kapha'),
                        BottomSheetOption(
                          value: 'Vata-Pitta',
                          label: 'Vata-Pitta',
                        ),
                        BottomSheetOption(
                          value: 'Pitta-Kapha',
                          label: 'Pitta-Kapha',
                        ),
                        BottomSheetOption(
                          value: 'Vata-Kapha',
                          label: 'Vata-Kapha',
                        ),
                        BottomSheetOption(
                          value: 'Sama Prakriti',
                          label: 'Sama Prakriti',
                        ),
                      ],
                    ),
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Sarataha (Tissue Quality)',
                      hint: 'Select Sarataha',
                      value: ctrl.sarataha.value,
                      onChanged: (v) => ctrl.sarataha.value = v,
                      options: _qualityOptions,
                    ),
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Sanhanan (Body Constitution)',
                      hint: 'Select Sanhanan',
                      value: ctrl.sanhanan.value,
                      onChanged: (v) => ctrl.sanhanan.value = v,
                      options: _qualityOptions,
                    ),
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Pramana (Body Proportion)',
                      hint: 'Select Pramana',
                      value: ctrl.pramana.value,
                      onChanged: (v) => ctrl.pramana.value = v,
                      options: _qualityOptions,
                    ),
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Satva (Mental Strength)',
                      hint: 'Select Satva',
                      value: ctrl.satva.value,
                      onChanged: (v) => ctrl.satva.value = v,
                      options: _qualityOptions,
                    ),
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Satmya (Adaptability)',
                      hint: 'Select Satmya',
                      value: ctrl.satmya.value,
                      onChanged: (v) => ctrl.satmya.value = v,
                      options: [
                        BottomSheetOption(
                          value: 'Sarvarasa Satmya',
                          label: 'Sarvarasa Satmya',
                        ),
                        BottomSheetOption(
                          value: 'Madhyama Satmya',
                          label: 'Madhyama Satmya',
                        ),
                        BottomSheetOption(
                          value: 'Ekarasa Satmya',
                          label: 'Ekarasa Satmya',
                        ),
                      ],
                    ),
                  ),

                  // Ahara + Vyayama Shakti side-by-side
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => AppBottomSheet<String>(
                            label: 'Ahara Shakti',
                            hint: 'Select',
                            value: ctrl.aharaShakti.value,
                            onChanged: (v) => ctrl.aharaShakti.value = v,
                            options: _shaktiOptions,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => AppBottomSheet<String>(
                            label: 'Vyayama Shakti',
                            hint: 'Select',
                            value: ctrl.vyayamaShakti.value,
                            onChanged: (v) => ctrl.vyayamaShakti.value = v,
                            options: _shaktiOptions,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Vaya (Age Group)',
                      hint: 'Select Vaya',
                      value: ctrl.vaya.value,
                      onChanged: (v) => ctrl.vaya.value = v,
                      options: [
                        BottomSheetOption(
                          value: 'Bala (Child 0–16)',
                          label: 'Bala (Child 0–16)',
                        ),
                        BottomSheetOption(
                          value: 'Madhyama (Adult 16–60)',
                          label: 'Madhyama (Adult 16–60)',
                        ),
                        BottomSheetOption(
                          value: 'Vriddha (Old 60+)',
                          label: 'Vriddha (Old 60+)',
                        ),
                      ],
                    ),
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Jihwa (Tongue)',
                      hint: 'Select Jihwa condition',
                      value: ctrl.jihwa.value,
                      onChanged: (v) => ctrl.jihwa.value = v,
                      options: [
                        BottomSheetOption(value: 'Clean', label: 'Clean'),
                        BottomSheetOption(value: 'Coated', label: 'Coated'),
                        BottomSheetOption(
                          value: 'Trembling',
                          label: 'Trembling',
                        ),
                        BottomSheetOption(value: 'Dry', label: 'Dry'),
                        BottomSheetOption(value: 'Moist', label: 'Moist'),
                      ],
                    ),
                  ),

                  Obx(
                    () => AppBottomSheet<String>(
                      label: 'Desha (Habitat)',
                      hint: 'Select Desha',
                      value: ctrl.desha.value,
                      onChanged: (v) => ctrl.desha.value = v,
                      options: [
                        BottomSheetOption(
                          value: 'Anupa (Marshy)',
                          label: 'Anupa (Marshy)',
                        ),
                        BottomSheetOption(
                          value: 'Jangala (Dry/Desert)',
                          label: 'Jangala (Dry/Desert)',
                        ),
                        BottomSheetOption(
                          value: 'Sadharana (Normal)',
                          label: 'Sadharana (Normal)',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          StickyNav(onPrev: ctrl.prev, onNext: ctrl.next),
        ],
      ),
    );
  }
}

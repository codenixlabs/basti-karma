import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/patient/patient_model.dart';
import '../screen/add_patient_screen.dart';
import 'patient_documents_sheet.dart';
import 'patient_pdf_report_dialog.dart';

/// A full-fidelity clinical Case Record Form (CRF) sheet displaying all
/// 9 categories of medical data recorded for a patient.
class PatientCaseSheetSheet extends StatelessWidget {
  final PatientModel patient;

  const PatientCaseSheetSheet({super.key, required this.patient});

  static Future<void> show(BuildContext context, PatientModel patient) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PatientCaseSheetSheet(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = patient;
    final isFemale = p.sex.trim().toLowerCase() == 'female';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & top header
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Case Record Form (CRF)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDarkGreen,
                        ),
                      ),
                      Text(
                        'Ayurvedic Clinical Intake Assessment',
                        style: TextStyle(fontSize: 11, color: AppColors.darkGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Download Full PDF Report',
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  onPressed: () => PatientPdfReportDialog.show(context, p),
                ),
                IconButton(
                  tooltip: 'Edit Patient Details',
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.to(() => AddPatientScreen(patientToEdit: p));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.darkGrey, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Patient Demographics & Hospital Information
                  _buildSectionCard(
                    context,
                    title: '1. Basic Info & Demographics',
                    icon: Icons.person_outline_rounded,
                    editStep: 0,
                    children: [
                      _buildRow2('Full Name', p.name, 'Sex', p.sex),
                      _buildRow2('Age', '${p.age} years', 'Phone', p.phoneNo ?? p.phone ?? '—'),
                      _buildRow2('Admission Type', p.admissionType, 'Blood Group', p.bloodGroup ?? '—'),
                      _buildRow2('OPD Number', p.opdNumber ?? p.opdNo ?? '—', 'IPD Number', p.ipdNumber ?? p.ipdNo ?? '—'),
                      _buildRow2('Occupation', p.occupation ?? '—', 'Marital Status', p.maritalStatus ?? '—'),
                      _buildRow2('Religion', p.religion ?? '—', 'Habitat (Desha)', p.desha.isNotEmpty ? p.desha : '—'),
                      if (p.address != null && p.address!.isNotEmpty)
                        _buildFullRow('Address', p.address!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Clinical Diagnosis & Complaints
                  _buildSectionCard(
                    context,
                    title: '2. Clinical Information & Diagnosis',
                    icon: Icons.medical_services_outlined,
                    editStep: 2,
                    children: [
                      _buildFullRow(
                        'Primary Diagnosis',
                        p.diagnosis.isNotEmpty ? p.diagnosis : 'Not specified',
                        isHighlighted: true,
                      ),
                      if (p.clinicalDiseaseSelection != null && p.clinicalDiseaseSelection!.isNotEmpty)
                        _buildFullRow('Clinical Disease Selection', p.clinicalDiseaseSelection!),
                      if (p.customDiagnosis != null && p.customDiagnosis!.isNotEmpty)
                        _buildFullRow('Custom Diagnosis', p.customDiagnosis!),
                      _buildFullRow('Chief Complaints', p.chiefComplaints ?? 'Not recorded'),
                      if (p.historyOfPresentIllness != null && p.historyOfPresentIllness!.isNotEmpty)
                        _buildFullRow('History of Present Illness', p.historyOfPresentIllness!),
                      if (p.historyOfPastIllness != null && p.historyOfPastIllness!.isNotEmpty)
                        _buildFullRow('History of Past Illness', p.historyOfPastIllness!),
                      if (p.familyHistory != null && p.familyHistory!.isNotEmpty)
                        _buildFullRow('Family History', p.familyHistory!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Vitals & General Physical Examination
                  _buildSectionCard(
                    context,
                    title: '3. General Examination & Vitals',
                    icon: Icons.monitor_heart_outlined,
                    editStep: isFemale ? 5 : 4,
                    children: [
                      _buildRow2('Blood Pressure', p.bp ?? '—', 'Heart Rate (Pulse)', p.hr != null ? '${p.hr} bpm' : '—'),
                      _buildRow2('Respiratory Rate', p.rr != null ? '${p.rr} /min' : '—', 'Temperature', p.temperature != null ? '${p.temperature} °F' : '—'),
                      _buildRow2(
                        'Weight',
                        p.weight != null ? '${p.weight} kg' : '—',
                        'Height',
                        p.height != null ? '${p.height} cm' : '—',
                      ),
                      if (p.bmi != null)
                        _buildFullRow(
                          'BMI',
                          '${p.bmi} kg/m² (${_getBmiCategory(p.bmi)})',
                          isHighlighted: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Ayurvedic Rogi Pariksha
                  _buildSectionCard(
                    context,
                    title: '4. Rogi Pariksha (Ayurvedic Constitution)',
                    icon: Icons.spa_outlined,
                    editStep: isFemale ? 6 : 5,
                    children: [
                      _buildRow2(
                        'Prakriti',
                        p.prakriti.isNotEmpty ? p.prakriti : '—',
                        'Desha (Habitat)',
                        p.desha.isNotEmpty ? p.desha : '—',
                        isKey: true,
                      ),
                      _buildRow2('Sarataha (Tissue Quality)', p.sarataha.isNotEmpty ? p.sarataha : '—', 'Sanhanan (Body Build)', p.sanhanan.isNotEmpty ? p.sanhanan : '—'),
                      _buildRow2('Pramana (Proportions)', p.pramana.isNotEmpty ? p.pramana : '—', 'Satva (Mental Strength)', p.satva.isNotEmpty ? p.satva : '—'),
                      _buildRow2('Satmya (Adaptability)', p.satmya.isNotEmpty ? p.satmya : '—', 'Vaya (Age Category)', p.vaya.isNotEmpty ? p.vaya : '—'),
                      _buildRow2('Ahara Shakti (Digestive)', p.aharaShakti.isNotEmpty ? p.aharaShakti : '—', 'Vyayama Shakti (Physical)', p.vyayamaShakti.isNotEmpty ? p.vyayamaShakti : '—'),
                      _buildFullRow('Jihwa (Tongue)', p.jihwa.isNotEmpty ? p.jihwa : '—'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Lifestyle & Personal Habits
                  _buildSectionCard(
                    context,
                    title: '5. Personal History & Lifestyle',
                    icon: Icons.restaurant_outlined,
                    editStep: 3,
                    children: [
                      _buildRow2('Ahara (Diet)', p.ahara ?? '—', 'Vihara (Activity)', p.vihara ?? '—'),
                      _buildRow2('Bowel Habits', p.bowelHabits ?? '—', 'Nidra (Sleep)', p.nidra ?? '—'),
                      _buildRow2('Urine Frequency', p.urineFrequency ?? '—', 'Addictions', p.addiction ?? 'None'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 6. Obstetric & Menstrual History (Female patients only)
                  if (isFemale) ...[
                    _buildSectionCard(
                      context,
                      title: '6. Menstrual & Obstetric History',
                      icon: Icons.female_rounded,
                      editStep: 4,
                      children: [
                        _buildFullRow('Menstrual History', p.menstrualHistory ?? 'Not recorded'),
                        _buildRow2(
                          'No. of Deliveries',
                          p.numberOfDeliveries?.toString() ?? '—',
                          'Abortions',
                          p.abortion?.toString() ?? '—',
                        ),
                        if (p.surgicalIntervention != null && p.surgicalIntervention!.isNotEmpty)
                          _buildFullRow('Surgical Intervention', p.surgicalIntervention!),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 7. Investigations & Lab/Radiological Findings
                  _buildSectionCard(
                    context,
                    title: isFemale ? '7. Investigations & Findings' : '6. Investigations & Findings',
                    icon: Icons.biotech_outlined,
                    editStep: isFemale ? 7 : 6,
                    children: [
                      _buildFullRow(
                        'Pathological & Radiological Findings',
                        (p.pathologicalRadiological != null && p.pathologicalRadiological!.trim().isNotEmpty)
                            ? p.pathologicalRadiological!
                            : 'No pathological or radiological findings recorded.',
                      ),
                      if (p.photoUrl != null && p.photoUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            final fullUrl = PatientDocumentsSheet.resolvePhotoUrl(p.photoUrl!);
                            PatientDocumentsSheet.openDocument(fullUrl);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  PatientDocumentsSheet.isPdfUrl(p.photoUrl)
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_outlined,
                                  color: AppColors.primaryGreen,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    PatientDocumentsSheet.getDocumentFileName(p.photoUrl),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primaryGreen),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 8. Intake Treatment
                  _buildSectionCard(
                    context,
                    title: isFemale ? '8. Intake Treatment Given' : '7. Intake Treatment Given',
                    icon: Icons.medication_outlined,
                    editStep: isFemale ? 8 : 7,
                    children: [
                      _buildFullRow(
                        'Treatment Given at Intake',
                        (p.treatmentGiven != null && p.treatmentGiven!.trim().isNotEmpty)
                            ? p.treatmentGiven!
                            : 'Basti Karma Protocol',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    int? editStep,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDarkGreen,
                    ),
                  ),
                ),
                if (editStep != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.to(
                        () => AddPatientScreen(
                          patientToEdit: patient,
                          initialStep: editStep,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 12,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow2(String l1, String v1, String l2, String v2, {bool isKey = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildItem(l1, v1, isKey: isKey)),
          const SizedBox(width: 12),
          Expanded(child: _buildItem(l2, v2, isKey: isKey)),
        ],
      ),
    );
  }

  Widget _buildFullRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey)),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: isHighlighted ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : EdgeInsets.zero,
            decoration: isHighlighted
                ? BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: isHighlighted ? AppColors.textDarkGreen : const Color(0xFF2C3E50),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value, {bool isKey = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isKey ? FontWeight.w600 : FontWeight.w500,
            color: isKey ? AppColors.primaryGreen : const Color(0xFF2C3E50),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  static String _getBmiCategory(num? bmi) {
    if (bmi == null) return '—';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 24.9) return 'Normal Weight';
    if (bmi < 29.9) return 'Overweight';
    return 'Obese';
  }
}

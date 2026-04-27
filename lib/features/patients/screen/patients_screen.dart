import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/widgets/custom_text_field.dart';
import '../widgets/patient_card.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _patients = [
    {
      'name': 'Rajesh Kumar',
      'age': 45,
      'diagnosis': 'Vata Imbalance',
      'active': true,
    },
    {
      'name': 'Priya Sharma',
      'age': 38,
      'diagnosis': 'Pitta Disorder',
      'active': true,
    },
    {
      'name': 'Amit Patel',
      'age': 52,
      'diagnosis': 'Kapha Excess',
      'active': true,
    },
    {
      'name': 'Sunita Verma',
      'age': 29,
      'diagnosis': 'Vata-Pitta',
      'active': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [_buildHeader(), _buildAddButton(), _buildPatientList()],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Patients",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          CustomTextField(
            controller: _searchController,
            label: '',
            hintText: 'Search patients...',
            icon: Icons.search,
            fillColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ── Add-patient button ────────────────────────────────────────────────────
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: CustomButton(
        text: 'Add New Patient',
        onPressed: () => Get.toNamed(AppRoutes.addPatient),
      ),
    );
  }

  // ── Patient list ──────────────────────────────────────────────────────────
  Widget _buildPatientList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final p = _patients[index];
          return PatientCard(
            name: p['name'],
            age: p['age'],
            diagnosis: p['diagnosis'],
            isActive: p['active'],
            onView: () {},
            onAssess: () {
              Get.toNamed(AppRoutes.assessment);
            },
            onDocs: () {},
            onDelete: () => setState(() => _patients.removeAt(index)),
          );
        },
      ),
    );
  }
}

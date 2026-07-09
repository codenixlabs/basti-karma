import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';
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
  String _searchQuery = '';

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

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    final q = _searchQuery.toLowerCase();
    return _patients
        .where((p) =>
            (p['name'] as String).toLowerCase().contains(q) ||
            (p['diagnosis'] as String).toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [_buildHeader(), _buildAddButton(), _buildPatientList()],
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
            style: AppTextStyles.pageTitle,
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
    final patients = _filteredPatients;
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final p = patients[index];
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
            onDelete: () {
              final original = _patients.indexOf(p);
              setState(() => _patients.removeAt(original));
            },
          );
        },
      ),
    );
  }
}

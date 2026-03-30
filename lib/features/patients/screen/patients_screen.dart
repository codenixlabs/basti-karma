import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_theme.dart';
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
          children: [
            // ── Header with gradient ──────────────────────────────
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
                  const SizedBox(height: 16),
                  // Search field — white background override inside header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: AppColors.textDarkGreen,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search patients...',
                        hintStyle: const TextStyle(
                          color: AppColors.darkGrey,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Add New Patient button ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(AppRoutes.addPatient);
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Add New Patient',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shadowColor: AppColors.primaryGreen.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            // ── Patient list ──────────────────────────────────────
            Expanded(
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
                    onAssess: () {},
                    onDocs: () {},
                    onDelete: () {
                      setState(() => _patients.removeAt(index));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

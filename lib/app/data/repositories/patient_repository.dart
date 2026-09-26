import 'dart:io';
import '../models/patient/patient_model.dart';

/// Abstract repository interface for patient persistence.
///
/// The UI and controllers depend only on this interface, implemented
/// by [ApiPatientRepository] backed by the backend REST API.
abstract class PatientRepository {
  /// Persists a new patient. Optionally uploads [photoFile]. Returns the patient's [PatientModel.id].
  Future<String> addPatient(PatientModel patient, {File? photoFile});

  /// Returns all patients sorted by creation date (newest first).
  Future<List<PatientModel>> getAllPatients();

  /// Returns the patient with [id], or null if not found.
  Future<PatientModel?> getPatient(String id);

  /// Replaces the stored record for [patient.id]. Optionally updates [photoFile].
  Future<void> updatePatient(PatientModel patient, {File? photoFile});

  /// Uploads or replaces a document/photo for [patientId]. Returns the updated photo URL.
  Future<String?> uploadPatientPhoto(String patientId, File photoFile);

  /// Removes the patient with [id] from the store.
  Future<void> deletePatient(String id);

  /// Downloads the complete patient PDF report containing all patient details,
  /// hospital info, and daily treatment karma assessments.
  /// Saves the binary response directly to a .pdf file on device storage.
  /// Returns the saved [File].
  Future<File> downloadPatientPdfReport(
    String patientId, {
    String? defaultFileName,
    Duration? timeout,
  });
}

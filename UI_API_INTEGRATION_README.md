# UI API Integration Guide

This document provides the necessary details for integrating the backend APIs with the UI. It includes endpoints, required payloads, and expected responses for Authentication, Patient Management (CRUD), and Poorva Karma routes.

## Base URL
Assuming local development, the base URL is: `https://bhastikarma-app-backend.onrender.com`

## Authentication Header
**Important:** All routes EXCEPT Login and Signup require an Authorization header with a Bearer token.
```http
Authorization: Bearer <your_jwt_token_here>
```

---

## 1. Authentication Routes

### 1.1 Send OTP (Before Signup)
Generates and sends a 6-digit OTP to the provided email address for verification.
- **Method & Endpoint:** `POST /api/auth/send-otp`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "email": "johndoe@example.com"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

### 1.2 Signup
Create a new doctor/user account.
- **Method & Endpoint:** `POST /api/auth/signup`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "name": "Dr. John Doe",
  "email": "johndoe@example.com",
  "password": "securepassword",
  "otp": "123456",
  "role": "doctor" // Optional, defaults to 'doctor'
}
```
- **Success Response (201 Created):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
    "name": "Dr. John Doe",
    "email": "johndoe@example.com",
    "role": "doctor"
  }
}
```

### 1.3 Login
Authenticate an existing user and get the JWT token.
- **Method & Endpoint:** `POST /api/auth/login`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "email": "johndoe@example.com",
  "password": "securepassword"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "User logged in successfully",
  "data": {
    "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
    "name": "Dr. John Doe",
    "email": "johndoe@example.com",
    "role": "doctor",
    "token": "eyJhbGciOiJIUzI1NiIsInR...", 
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR..." 
  }
}
```

### 1.4 Refresh Token
Get a new access token when the current one expires.
- **Method & Endpoint:** `POST /api/auth/refresh`
- **Headers:** `Content-Type: application/json` (No Bearer token required)
- **Payload:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR..."
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "token": "new_access_token_here",
    "refreshToken": "new_refresh_token_here"
  }
}
```

### 1.5 Update Doctor Profile
Update the logged-in doctor's profile information.
- **Method & Endpoint:** `PUT /api/auth/profile`
- **Headers:** `Content-Type: application/json`, `Authorization: Bearer <token>`
- **Payload:** (All fields are optional, send only what needs updating)
```json
{
  "name": "Dr. Jane Doe",
  "email": "janedoe@example.com",
  "password": "newpassword123"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
    "name": "Dr. Jane Doe",
    "email": "janedoe@example.com",
    "role": "doctor"
  }
}
```

### 1.6 Forgot Password (Send OTP)
Generates and sends a 6-digit OTP to the user's email to reset their password.
- **Method & Endpoint:** `POST /api/auth/forgot-password`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "email": "johndoe@example.com"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset OTP sent successfully"
}
```

### 1.7 Verify OTP for Password Reset
Validates the OTP and returns a secure, temporary token (valid for 15 minutes) so the user can securely set their new password.
- **Method & Endpoint:** `POST /api/auth/verify-reset-otp`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "email": "johndoe@example.com",
  "otp": "123456"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "resetToken": "eyJhbGciOiJIUzI1NiIsInR..." 
  }
}
```

### 1.8 Reset Password
Takes the temporary token and sets the new password.
- **Method & Endpoint:** `POST /api/auth/reset-password`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "email": "johndoe@example.com",
  "resetToken": "eyJhbGciOiJIUzI1NiIsInR...",
  "newPassword": "myNewSecurePassword"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

## 2. Patient Routes (CRUD)

### 2.1 Create a Patient
- **Method & Endpoint:** `POST /api/patients`
- **Headers:** `Content-Type: application/json` (or `multipart/form-data` if uploading a photo)
- **Payload (JSON Example):**
```json
{
  "demographics": {
    "fullName": "Jane Smith",
    "age": 45,
    "sex": "Female",
    "religion": "Hindu",
    "occupation": "Teacher",
    "maritalStatus": "Married",
    "address": "123 Main St",
    "phoneNo": "9876543210"
  },
  "hospitalInfo": {
    "admissionType": "OPD",
    "opdNumber": "OPD1234",
    "ipdNumber": "IPD1234",
    "clinicalDiseaseSelection": "Arthritis",
    "customDiagnosis": "Rheumatoid Arthritis"
  },
  "ClinicalInformation": {
    "chiefComplaints": "Severe joint pain",
    "historyOfPresentIllness": "Pain started 2 months ago",
    "historyOfPastIllness": "None",
    "familyHistory": "Mother had arthritis"
  },
  "personalHistory": {
    "ahara": "Veg",
    "vihara": "Sedentary",
    "addiction": "None",
    "bowelHabits": "Regular",
    "nidra": "Sound",
    "urineFrequency": "Normal",
    "bloodGroup": "O+"
  },
  "generalExamination": {
    "bp": "120/80",
    "rr": "18",
    "hr": "72",
    "temperature": "98.6",
    "weight": 65,
    "height": 160,
    "bmi": 25.4
  },
  "treatment": "Basti"
}
```
*Note: If you need to upload a photo, send the data as `multipart/form-data` and include the file in a field named `photo`.*
- **Success Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "_id": "64f2b3c4d5e6f7a8b9c0d1e2",
    "demographics": { ... },
    // ... complete patient object
  }
}
```

### 2.2 Get All Patients (for logged-in doctor)
- **Method & Endpoint:** `GET /api/patients`
- **Payload:** None
- **Success Response (200 OK):**
```json
{
  "success": true,
  "count": 10,
  "data": [
    {
      "_id": "64f2b3c4d5e6f7a8b9c0d1e2",
      "demographics": { "fullName": "Jane Smith", ... },
      // ... patient object details
    }
  ]
}
```

### 2.3 Get Single Patient by ID
- **Method & Endpoint:** `GET /api/patients/:id`
- **Payload:** None
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "_id": "64f2b3c4d5e6f7a8b9c0d1e2",
    "demographics": { "fullName": "Jane Smith", ... },
    // ... full patient object details
  }
}
```

### 2.4 Update a Patient
- **Method & Endpoint:** `PUT /api/patients/:id`
- **Headers:** `Content-Type: application/json` (or `multipart/form-data` if uploading a photo)
- **Payload:** Send only the fields you want to update (similar to the Create Patient payload).
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "_id": "64f2b3c4d5e6f7a8b9c0d1e2",
    // ... updated patient object details
  }
}
```

### 2.5 Delete a Patient
- **Method & Endpoint:** `DELETE /api/patients/:id`
- **Payload:** None
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Patient removed successfully"
}
```

### 2.6 Download Patient PDF Report
- **Method & Endpoint:** `GET /api/patients/:id/pdf`
- **Headers:** `Authorization: Bearer <token>`, `Accept: application/pdf, application/json`
- **What it does:** Generates and downloads a complete PDF report containing all patient details, hospital information, and their daily treatment (Karma) assessments.
- **Success Response (200 OK):**
  - **Content-Type:** `application/pdf`
  - **Headers:** `Content-Disposition: attachment; filename="<Patient_Name>_Report.pdf"`
  - **Body:** Binary PDF byte stream.
- **Error Responses:**
  - `404 Not Found`: `{ "success": false, "message": "Patient not found or unauthorized" }`
  - `500 Internal Server Error`: `{ "success": false, "message": "Failed to generate PDF" }`

---

## 3. Poorva Karma Routes
These routes evaluate specific parameters before the primary treatment. All of them use the Patient ID in the URL.

### 3.1 Update Niruha Eligibility
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/niruha`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "recentInternalSnehanaEtc": false,
  "continuousVomitingEtc": false,
  "historyOfMiscarriageOrPregnant": false,
  "uncontrolledDiabetesHypertensionCkd": false
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "isEligible": true,
  "message": "Eligible"
}
```

### 3.2 Update Anuvasana Eligibility
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/anuvasana`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "hasAsthapanaContraindications": false,
  "impairedDigestion": false,
  "diarrhoeaOrHardBowel": false,
  "intestinalWormsPleehaEtc": false,
  "aruchiPoisoningCoryzaEtc": false
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "isEligible": true,
  "message": "Eligible"
}
```

### 3.3 Update Pariksha
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/pariksha`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "prakriti": "Vata-Pitta",
  "sarataha": "Madhyam",
  "sanhanan": "Pravara",
  "pramana": "Madhyam",
  "satva": "Pravara",
  "satmya": "Madhyam",
  "aharaShakti": "Pravara",
  "vyayamaShakti": "Madhyam",
  "vaya": "Madhyam",
  "jihwa": "Nirlipta"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "prakriti": "Vata-Pitta",
    // ... other pariksha fields saved
  }
}
```

### 3.4 Update Agni Assessment
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/agni`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "jaranShaktiScore": 3,
  "abhyavaharanaShaktiScore": 3,
  "ruchiScore": 4,
  "recommendedDrugs": "Chitrakadi Vati"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "totalScore": 10,
  "agniType": "Madhyam Agni(sama agni)",
  "data": {
    "jaranShaktiScore": 3,
    "abhyavaharanaShaktiScore": 3,
    "ruchiScore": 4,
    "totalScore": 10,
    "agniType": "Madhyam Agni(sama agni)",
    "recommendedDrugs": "Chitrakadi Vati"
  }
}
```

### 3.5 Update Kostha Assessment
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/kostha`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "bowelFrequencyScore": 2,
  "consistencyScore": 2,
  "urgencyScore": 1,
  "patientExperienceScore": 2,
  "foodHabitChangeScore": 1
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "totalScore": 8,
  "kosthaType": "Madhyam kostha",
  "data": {
    // ... saved kostha object data
  }
}
```

### 3.6 Update Saama Nirama Lakshana
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/saama-nirama`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "srotorodha": false,
  "balabhransha": false,
  "gaurava": true,
  "alasya": false,
  "anilaMudhata": false,
  "apaki": false,
  "nishthivana": false,
  "malaSanga": false,
  "aruchi": true,
  "klama": false
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "deepanPachanaRequired": true,
  "data": {
    "gaurava": true,
    "aruchi": true,
    "deepanPachanaRequired": true
    // ... rest of the symptoms
  }
}
```

### 3.7 Update Bala
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/bala`
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "bala": "Madhyam"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "bala": "Madhyam"
}
```

### 3.8 Mark Poorva Karma Completed
- **Method & Endpoint:** `PUT /api/poorva-karma/:patientId/complete`
- **Payload:** None (empty object `{}` is fine if client requires body)
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Poorva Karma marked as completed",
  "data": {
    "poorvaKarmaCompleted": true,
    "pradhanaKarmaCompleted": false,
    "paschataKarmaCompleted": false
  }
}
```

### 3.9 Get Poorva Karma Details
- **Method & Endpoint:** `GET /api/poorva-karma/:patientId`
- **Purpose:** Retrieves the entire Poorva Karma assessment for the specified patient.
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "_id": "650c1234abcd567890ef1234",
    "patientId": { "_id": "...", "demographics": { "fullName": "Jane Smith" } },
    "doctorId": { "_id": "...", "name": "Dr. John Doe" },
    "pariksha": { ... },
    "agniAssessment": { ... }
    // ... all other poorva karma sections
  }
}
```

---

## 4. Paschata Karma Routes
These routes handle the post-treatment assessment (Paschata Karma) for a patient. All endpoints require the `Authorization` header.

### 4.1 Create or Update Paschata Karma
- **Method & Endpoint:** `PUT /api/paschata-karma/:patientId`
- **Headers:** `Content-Type: application/json`
- **Purpose:** Creates or updates the post-treatment assessment complications.
- **Payload:**
```json
{
  "vyapadaAndManagement": {
    "niruhaVyapada": "ayoga",
    "anuvasanaVyapada": "none"
  }
}
```
*Note: The `niruhaVyapada` and `anuvasanaVyapada` fields accept a single string representing the selected complication (e.g., 'ayoga', 'atiyoga', 'klama', 'none', etc.). The Flutter app should use this value to display the appropriate treatment (Chikitsa) text locally.*
- **Success Response (200 OK or 201 Created):**
```json
{
  "success": true,
  "message": "Paschata Karma updated successfully",
  "data": {
    "patientId": "64f2b3c4d5e6f7a8b9c0d1e2",
    "doctorId": "64f1a2b3c4d5e6f7a8b9c0d1",
    "vyapadaAndManagement": {
      "niruhaVyapada": "ayoga",
      "anuvasanaVyapada": "none"
    },
    "_id": "650c1234abcd567890ef1234"
  }
}
```

### 4.2 Get Paschata Karma Details
- **Method & Endpoint:** `GET /api/paschata-karma/:patientId`
- **Purpose:** Retrieves the saved Paschata Karma assessment for the specified patient.
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "patientId": {
      "_id": "64f2b3c4d5e6f7a8b9c0d1e2",
      "demographics": {
        "fullName": "Jane Smith"
      }
    },
    "doctorId": {
      "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
      "name": "Dr. John Doe"
    },
    "vyapadaAndManagement": {
      "niruhaVyapada": "ayoga",
      "anuvasanaVyapada": "none"
    },
    "_id": "650c1234abcd567890ef1234"
  }
}
```

---

## 5. Pradhana Karma Routes
All endpoints require the `Authorization` header with a Bearer token.

### 5.1 Get Pradhana Karma Details
- **Method & Endpoint:** `GET /api/pradhana-karma/:patientId`
- **Purpose:** Retrieves the complete state of the Pradhana Karma treatment (for resume/continuation).
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "patientId": { "_id": "...", "demographics": { "fullName": "Jane Smith" } },
    "doctorId": { "_id": "...", "name": "Dr. John Doe" },
    "diseaseId": { "_id": "...", "diseaseName": "Arthritis" },
    "bastiFormulationId": { "_id": "...", "formulationName": "Erandamooladi Niruha Basti" },
    "bastiPatternCode": "KARMA",
    "patternName": "Karma Basti",
    "totalDays": 30,
    "sequence": ["A", "N", "A"],
    "treatmentStatus": "PLANNED",
    "startDate": "2023-10-15T10:00:00.000Z",
    "observation": {
      "dailyObservations": [
        {
          "day": 1,
          "date": "2023-10-15T10:00:00.000Z",
          "bastiType": "A",
          "status": "PENDING"
        }
      ]
    }
  }
}
```

### 5.2 Initialize or Update Pradhana Karma
- **Method & Endpoint:** `PUT /api/pradhana-karma/:patientId`
- **Purpose:** Sets or updates the selected disease, basti pattern, formulation, and start date. It automatically generates the daily observations schedule if `startDate` and `bastiPatternCode` are provided.
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "diseaseId": "64f1...",
  "bastiPatternCode": "YOGA",
  "bastiFormulationId": "64f2...",
  "customNotesOnDose": "Reduced honey by 10ml",
  "startDate": "2023-10-15T10:00:00.000Z",
  "treatmentStatus": "PLANNED"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "_id": "651b...",
    "patientId": "...",
    "doctorId": "...",
    "diseaseId": "...",
    "bastiPatternCode": "YOGA",
    "patternName": "Yoga Basti",
    "totalDays": 8,
    "sequence": ["A", "N", "A", "N", "A", "N", "A", "A"],
    "bastiFormulationId": "...",
    "treatmentStatus": "PLANNED",
    "startDate": "2023-10-15T10:00:00.000Z",
    "observation": {
       "dailyObservations": [
         // ... auto-generated array of 8 days
       ]
    }
  }
}
```

### 5.3 Add Daily Observation
- **Method & Endpoint:** `POST /api/pradhana-karma/:patientId/observations`
- **Purpose:** Adds or updates an observation for a specific day of the treatment.
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "day": 1,
  "status": "COMPLETED",
  "dose": "450ml",
  "timeAdministered": "10:30 AM",
  "notes": "Patient tolerated well",
  "prasristaVinaMutra": true,
  "sameerantwama": true,
  "agniVriddhi": false
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "day": 1,
      "date": "2023-10-15T10:00:00.000Z",
      "bastiType": "A",
      "status": "COMPLETED",
      "prasristaVinaMutra": true,
      "sameerantwama": true
    }
  ]
}
```

### 5.4 Update Daily Observation
- **Method & Endpoint:** `PUT /api/pradhana-karma/:patientId/observations/:day`
- **Purpose:** Updates an existing observation for a specific day in the URL.
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{
  "status": "COMPLETED",
  "dose": "450ml",
  "prasristaVinaMutra": true,
  "sameerantwama": true
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "day": 1,
    "bastiType": "A",
    "status": "COMPLETED",
    "prasristaVinaMutra": true,
    "sameerantwama": true
  }
}
```

### 5.5 Mark Pradhana Karma Completed
- **Method & Endpoint:** `PUT /api/pradhana-karma/:patientId/complete`
- **Purpose:** Marks the overall Pradhana Karma as completed in the patient's assessment status.
- **Headers:** `Content-Type: application/json`
- **Payload:**
```json
{}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Pradhana Karma marked as completed",
  "data": {
    "poorvaKarmaCompleted": true,
    "pradhanaKarmaCompleted": true,
    "paschataKarmaCompleted": false
  }
}
```

---

## 6. Resource (PDF) Routes
These routes handle fetching and uploading PDF resources like standard operating procedures.

### 6.1 Get All Resources
- **Method & Endpoint:** `GET /api/resources`
- **Purpose:** Retrieves a list of all available PDFs. (If none exist, it will auto-generate a demo PDF for testing).
- **Success Response (200 OK):**
```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "_id": "651a2b3c4d5e6f7a8b9c0d12",
      "title": "Basti Karma Standard Operating Procedure",
      "description": "A demo PDF document outlining the standard guidelines for Basti Karma.",
      "fileUrl": "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
      "fileType": "pdf",
      "createdAt": "2023-10-01T12:00:00.000Z"
    }
  ]
}
```

### 6.2 Upload a New Resource
- **Method & Endpoint:** `POST /api/resources`
- **Headers:** `Content-Type: multipart/form-data`
- **Purpose:** Uploads a new PDF to Cloudinary and saves the metadata.
- **Payload (Form Data):**
  - `title` (text) - The title of the resource.
  - `description` (text) - Optional description.
  - `file` (file) - The actual PDF file to upload.
- **Success Response (201 Created):**
```json
{
  "success": true,
  "message": "Resource uploaded and created successfully",
  "data": {
    "_id": "651a2b3c4d5e6f7a8b9c0d12",
    "title": "Uploaded PDF Title",
    "description": "Uploaded description",
    "fileUrl": "https://res.cloudinary.com/your-cloud-name/raw/upload/v12345/bhastikarma/resources/xyz.pdf",
    "fileType": "pdf"
  }
}
```

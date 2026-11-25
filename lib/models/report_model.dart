class User {
  final String uid;
  final String name;
  final String email;
  final String role; // "patient", "doctor", "hospital_admin"
  final String phone;
  final String? mrn;
  final String? doctorId;
  final String? hospitalId;
  final String? specialty;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.mrn,
    this.doctorId,
    this.hospitalId,
    this.specialty,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      phone: json['phone'] ?? '',
      mrn: json['mrn'],
      doctorId: json['doctor_id'],
      hospitalId: json['hospital_id'],
      specialty: json['specialty'],
    );
  }
}

class ReportParameter {
  final String name;
  final String value;
  final String referenceRange;
  final String status;
  final String explanation;
  final String biologicalLimitations;

  ReportParameter({
    required this.name,
    required this.value,
    required this.referenceRange,
    required this.status,
    required this.explanation,
    this.biologicalLimitations = '',
  });

  factory ReportParameter.fromJson(Map<String, dynamic> json) {
    return ReportParameter(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      referenceRange: json['reference_range'] ?? 'N/A',
      status: json['status'] ?? 'Normal',
      explanation: json['explanation'] ?? '',
      biologicalLimitations: json['biological_limitations'] ?? '',
    );
  }
}

class DoctorNote {
  final String id;
  final String doctorName;
  final String notes;
  final String prescription;
  final String createdAt;

  DoctorNote({
    required this.id,
    required this.doctorName,
    required this.notes,
    this.prescription = '',
    required this.createdAt,
  });

  factory DoctorNote.fromJson(Map<String, dynamic> json) {
    return DoctorNote(
      id: json['id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      notes: json['notes'] ?? '',
      prescription: json['prescription'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class MedicalReport {
  final String id;
  final String token;
  final String patientName;
  final String filename;
  final String createdAt;
  final String reportType;
  final String source;
  final String reportTitle;
  final String summaryOverview;
  final String disclaimer;
  final List<ReportParameter> parameters;
  final List<String> generalObservations;
  final List<String> questionsForDoctor;
  final List<DoctorNote> doctorNotes;

  MedicalReport({
    required this.id,
    required this.token,
    required this.patientName,
    required this.filename,
    required this.createdAt,
    this.reportType = 'Laboratory Pathology',
    this.source = 'Uploaded by Patient',
    required this.reportTitle,
    required this.summaryOverview,
    required this.disclaimer,
    required this.parameters,
    required this.generalObservations,
    required this.questionsForDoctor,
    required this.doctorNotes,
  });

  factory MedicalReport.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] ?? {};
    final paramsList = (analysis['parameters'] as List<dynamic>? ?? [])
        .map((p) => ReportParameter.fromJson(p as Map<String, dynamic>))
        .toList();

    final obsList = (analysis['general_observations'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final qList = (analysis['questions_for_doctor'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final notesList = (json['doctor_notes'] as List<dynamic>? ?? [])
        .map((n) => DoctorNote.fromJson(n as Map<String, dynamic>))
        .toList();

    return MedicalReport(
      id: json['id'] ?? '',
      token: json['token'] ?? '',
      patientName: json['patient_name'] ?? 'Patient',
      filename: json['filename'] ?? '',
      createdAt: json['created_at'] ?? '',
      reportType: json['report_type'] ?? 'Laboratory Pathology',
      source: json['source'] ?? 'Uploaded by Patient',
      reportTitle: analysis['report_title'] ?? 'Laboratory Report',
      summaryOverview: analysis['summary_overview'] ?? '',
      disclaimer: analysis['disclaimer'] ?? 'For educational purposes only. Does not diagnose diseases.',
      parameters: paramsList,
      generalObservations: obsList,
      questionsForDoctor: qList,
      doctorNotes: notesList,
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final String hospital;
  final String hospitalId;
  final String avatar;
  final List<String> availableDays;
  final String availableTime;
  final List<String> offDates;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.hospital,
    this.hospitalId = 'hosp_1',
    required this.avatar,
    this.availableDays = const ['Mon', 'Wed', 'Fri'],
    this.availableTime = '09:00 AM - 04:00 PM',
    this.offDates = const [],
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      qualification: json['qualification'] ?? '',
      hospital: json['hospital'] ?? '',
      hospitalId: json['hospital_id'] ?? 'hosp_1',
      avatar: json['avatar'] ?? '',
      availableDays: (json['available_days'] as List<dynamic>? ?? ['Mon', 'Wed', 'Fri']).map((e) => e.toString()).toList(),
      availableTime: json['available_time'] ?? '09:00 AM - 04:00 PM',
      offDates: (json['off_dates'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class Hospital {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final List<String> departments;
  final List<String> doctorIds;
  final double rating;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.departments,
    required this.doctorIds,
    this.rating = 4.8,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      departments: (json['departments'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      doctorIds: (json['doctor_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }
}

class Pairing {
  final String id;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String hospital;
  final String status;
  final String createdAt;

  Pairing({
    required this.id,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.status,
    required this.createdAt,
  });

  factory Pairing.fromJson(Map<String, dynamic> json) {
    return Pairing(
      id: json['id'] ?? '',
      patientName: json['patient_name'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      specialty: json['specialty'] ?? '',
      hospital: json['hospital'] ?? '',
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class HospitalPairing {
  final String id;
  final String patientName;
  final String hospitalId;
  final String hospitalName;
  final String mrn;
  final String status;
  final String createdAt;

  HospitalPairing({
    required this.id,
    required this.patientName,
    required this.hospitalId,
    required this.hospitalName,
    required this.mrn,
    required this.status,
    required this.createdAt,
  });

  factory HospitalPairing.fromJson(Map<String, dynamic> json) {
    return HospitalPairing(
      id: json['id'] ?? '',
      patientName: json['patient_name'] ?? '',
      hospitalId: json['hospital_id'] ?? '',
      hospitalName: json['hospital_name'] ?? '',
      mrn: json['mrn'] ?? '',
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Appointment {
  final String id;
  final String patientName;
  final String patientPhone;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String hospital;
  final String hospitalId;
  final String date;
  final String time;
  final String reason;
  final String? reportToken;
  final String status;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.hospital,
    this.hospitalId = 'hosp_1',
    required this.date,
    required this.time,
    required this.reason,
    this.reportToken,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      patientName: json['patient_name'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      doctorSpecialty: json['doctor_specialty'] ?? '',
      hospital: json['hospital'] ?? '',
      hospitalId: json['hospital_id'] ?? 'hosp_1',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      reason: json['reason'] ?? '',
      reportToken: json['report_token'],
      status: json['status'] ?? 'Confirmed',
    );
  }
}

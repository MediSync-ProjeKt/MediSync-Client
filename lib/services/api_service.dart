import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';

class ApiService {
  // Use http://10.0.2.2:8000 for Android emulator, http://127.0.0.1:8000 for web/desktop/linux
  static String baseUrl = "http://127.0.0.1:8000";

  // Active simulated session
  static User? currentUser;

  // ------------------ Layer 0: Authentication ------------------

  static Future<User?> login(String email, String password, {String? role}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password, "role": role}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['user'] != null) {
          currentUser = User.fromJson(data['user']);
          return currentUser;
        }
      }
    } catch (e) {
      // Offline fallback for seamless demo
    }
    return null;
  }

  static Future<User?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? specialty,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
          "name": name,
          "role": role,
          "phone": phone,
          "specialty": specialty,
        }),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['user'] != null) {
          currentUser = User.fromJson(data['user']);
          return currentUser;
        }
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  // ------------------ Layer 1: Centralized Medical Vault & AI ------------------

  static Future<List<MedicalReport>> getReports({String? patientName, String? reportType}) async {
    try {
      String url = "$baseUrl/api/reports";
      List<String> queryParams = [];
      if (patientName != null && patientName.isNotEmpty) {
        queryParams.add("patient_name=${Uri.encodeComponent(patientName)}");
      }
      if (reportType != null && reportType.isNotEmpty) {
        queryParams.add("report_type=${Uri.encodeComponent(reportType)}");
      }
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join('&')}";
      }

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        return list.map((item) => MedicalReport.fromJson(item)).toList();
      }
    } catch (e) {
      // Handle error gracefully
    }
    return [];
  }

  static Future<MedicalReport?> loadSampleReport(String sampleType, {String patientName = "Sarah Connor", String source = "Clinical Sample Demonstration"}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/sample-report?sample_type=$sampleType&patient_name=${Uri.encodeComponent(patientName)}&source=${Uri.encodeComponent(source)}"),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['record'] != null) {
          return MedicalReport.fromJson(data['record']);
        }
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  static Future<MedicalReport?> uploadReportBytes(Uint8List bytes, String filename, String patientName, {String reportType = "Laboratory Pathology"}) async {
    try {
      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/api/analyze-report"));
      request.fields['patient_name'] = patientName;
      request.fields['report_type'] = reportType;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['record'] != null) {
          return MedicalReport.fromJson(data['record']);
        }
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  static Future<MedicalReport?> getReportByToken(String token) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/reports/$token"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return MedicalReport.fromJson(data);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  static Future<bool> deleteReport(String reportId) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/api/reports/$reportId"));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> sendChatMessage({
    required String message,
    String? reportId,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "message": message,
          "report_id": reportId,
          "history": history,
        }),
      );
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  static Future<Map<String, dynamic>?> askVoiceQuery(String queryText, {String? reportId}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/voice/query"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"query_text": queryText, "report_id": reportId}),
      );
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  // ------------------ Layer 2: Patient-Doctor Ecosystem & Pairing ------------------

  static Future<List<Doctor>> getDoctors() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/doctors"));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        return list.map((d) => Doctor.fromJson(d)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  static Future<bool> updateDoctorSchedule(String docId, {required List<String> availableDays, String? availableTime, List<String>? offDates}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/doctors/$docId/schedule"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "available_days": availableDays,
          "available_time": availableTime,
          "off_dates": offDates ?? [],
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Pairing>> getPairings({String? doctorId, String? patientName}) async {
    try {
      String url = "$baseUrl/api/pairings";
      List<String> q = [];
      if (doctorId != null) q.add("doctor_id=$doctorId");
      if (patientName != null) q.add("patient_name=${Uri.encodeComponent(patientName)}");
      if (q.isNotEmpty) url += "?${q.join('&')}";

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        return list.map((p) => Pairing.fromJson(p)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  static Future<Pairing?> createPairing({required String patientName, required String doctorId, String? notes}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/pairings"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "patient_name": patientName,
          "doctor_id": doctorId,
          "notes": notes,
        }),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['pairing'] != null) {
          return Pairing.fromJson(data['pairing']);
        }
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  static Future<bool> bookAppointment({
    required String patientName,
    required String patientPhone,
    required String doctorId,
    required String date,
    required String time,
    required String reason,
    String? hospitalId,
    String? reportToken,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/appointments"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "patient_name": patientName,
          "patient_phone": patientPhone,
          "doctor_id": doctorId,
          "date": date,
          "time": time,
          "reason": reason,
          "hospital_id": hospitalId,
          "report_token": reportToken,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Appointment>> getAppointments({String? doctorId, String? patientName, String? hospitalId}) async {
    try {
      String url = "$baseUrl/api/appointments";
      List<String> q = [];
      if (doctorId != null) q.add("doctor_id=$doctorId");
      if (patientName != null) q.add("patient_name=${Uri.encodeComponent(patientName)}");
      if (hospitalId != null) q.add("hospital_id=$hospitalId");
      if (q.isNotEmpty) url += "?${q.join('&')}";

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        return list.map((a) => Appointment.fromJson(a)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  static Future<bool> updateAppointmentStatus(String apptId, String status) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/appointments/$apptId/status"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addDoctorNotes(String reportId, String doctorName, String notes, {String? prescription}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/reports/$reportId/notes"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "doctor_name": doctorName,
          "notes": notes,
          "prescription": prescription ?? "",
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ------------------ Layer 3: Hospital Administration Client ------------------

  static Future<List<Hospital>> getHospitals() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/hospitals"));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        return list.map((h) => Hospital.fromJson(h)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  static Future<List<HospitalPairing>> getHospitalPairings({String? patientName}) async {
    try {
      String url = "$baseUrl/api/hospital-pairings";
      if (patientName != null) url += "?patient_name=${Uri.encodeComponent(patientName)}";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        return list.map((hp) => HospitalPairing.fromJson(hp)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  static Future<HospitalPairing?> pairWithHospital(String hospitalId, String patientName) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/hospitals/$hospitalId/pair"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"patient_name": patientName}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['pairing'] != null) {
          return HospitalPairing.fromJson(data['pairing']);
        }
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  static Future<bool> deliverHospitalReport({
    required String hospitalId,
    required String patientName,
    required String sampleType,
    String? clinicalNotes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/hospitals/$hospitalId/reports/deliver"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "patient_name": patientName,
          "sample_type": sampleType,
          "clinical_notes": clinicalNotes,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getHospitalAnalytics(String hospitalId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/hospitals/$hospitalId/analytics"));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }
}

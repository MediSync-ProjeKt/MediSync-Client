import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/metric_tile.dart';

class DoctorPortalScreen extends StatefulWidget {
  final MedicalReport? initialReport;
  final VoidCallback? onLogout;

  const DoctorPortalScreen({super.key, this.initialReport, this.onLogout});

  @override
  State<DoctorPortalScreen> createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tokenCtrl = TextEditingController();
  final _docNameCtrl = TextEditingController(text: "Dr. Sarah Jenkins");
  final _notesCtrl = TextEditingController();
  final _prescriptionCtrl = TextEditingController();

  MedicalReport? _patientReport;
  bool _isLoading = false;
  bool _isSavingNotes = false;
  List<Appointment> _doctorAppointments = [];
  List<Pairing> _pairedPatients = [];

  // Doctor Schedule Management
  Doctor? _currentDoctor;
  List<String> _availableDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  String _availableTime = "09:00 AM - 04:00 PM";
  final List<String> _offDates = ["2026-11-29", "2026-12-05"];
  final _newOffDateCtrl = TextEditingController();
  bool _isSavingSchedule = false;

  final List<String> _allWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialReport != null) {
      _patientReport = widget.initialReport;
      _tokenCtrl.text = widget.initialReport!.token;
    }
    _loadDoctorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tokenCtrl.dispose();
    _docNameCtrl.dispose();
    _notesCtrl.dispose();
    _prescriptionCtrl.dispose();
    _newOffDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorData() async {
    final docs = await ApiService.getDoctors();
    final appts = await ApiService.getAppointments(doctorId: "doc_1");
    final pairs = await ApiService.getPairings(doctorId: "doc_1");

    Doctor? currentDoc;
    if (docs.isNotEmpty) {
      currentDoc = docs.firstWhere((d) => d.id == "doc_1", orElse: () => docs.first);
    }

    setState(() {
      _currentDoctor = currentDoc;
      if (currentDoc != null) {
        _availableDays = List.from(currentDoc.availableDays);
        _availableTime = currentDoc.availableTime;
        _offDates.addAll(currentDoc.offDates.where((d) => !_offDates.contains(d)));
      }
      _doctorAppointments = appts;
      _pairedPatients = pairs;
    });
  }

  Future<void> _fetchReport() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;

    setState(() => _isLoading = true);
    final report = await ApiService.getReportByToken(token);
    setState(() {
      _isLoading = false;
      _patientReport = report;
    });

    if (report == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No medical record located with this access token"), backgroundColor: AppColors.critical),
      );
    }
  }

  Future<void> _saveNotes() async {
    if (_patientReport == null || _notesCtrl.text.trim().isEmpty) return;

    setState(() => _isSavingNotes = true);
    final success = await ApiService.addDoctorNotes(
      _patientReport!.id,
      _docNameCtrl.text.trim(),
      _notesCtrl.text.trim(),
      prescription: _prescriptionCtrl.text.trim(),
    );
    setState(() => _isSavingNotes = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Clinical consultation note & Rx attached to patient chart"),
          backgroundColor: AppColors.primary,
        ),
      );
      _notesCtrl.clear();
      _prescriptionCtrl.clear();
      _fetchReport();
    }
  }

  Future<void> _updateStatus(String apptId, String newStatus) async {
    final success = await ApiService.updateAppointmentStatus(apptId, newStatus);
    if (success) {
      _loadDoctorData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Appointment marked as $newStatus"), backgroundColor: AppColors.primary),
      );
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSavingSchedule = true);
    final success = await ApiService.updateDoctorSchedule(
      "doc_1",
      availableDays: _availableDays,
      availableTime: _availableTime,
      offDates: _offDates,
    );
    setState(() => _isSavingSchedule = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Schedule & availability preferences updated!"), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated local schedule configuration"), backgroundColor: AppColors.primary),
      );
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_availableDays.contains(day)) {
        if (_availableDays.length > 1) {
          _availableDays.remove(day);
        }
      } else {
        _availableDays.add(day);
      }
    });
  }

  void _addOffDate() {
    final text = _newOffDateCtrl.text.trim();
    if (text.isNotEmpty && !_offDates.contains(text)) {
      setState(() {
        _offDates.add(text);
        _newOffDateCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Navigation
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(icon: Icon(Icons.qr_code_scanner_outlined, size: 18), text: "Receive Medical Data"),
              Tab(icon: Icon(Icons.event_note_outlined, size: 18), text: "Appointments Queue"),
              Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: "Manage Schedule"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChartTab(),
              _buildQueueTab(),
              _buildScheduleTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------ Tab 1: Receive Medical Data via QR / Token ------------------

  Widget _buildChartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Doctor ID Header Banner
          AppCard(
            variant: CardVariant.sage,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_docNameCtrl.text, style: AppTypography.h3),
                      const Text(
                        "Cardiology Specialist • MediSync Metro Health City • License #MD-48192",
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (widget.onLogout != null)
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.primaryDark),
                    tooltip: "Sign Out",
                    onPressed: widget.onLogout,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Token / QR Scan Card
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text("Receive Patient Medical Data", style: AppTypography.h3),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Scan patient QR pass or enter report token (JWT token) to securely load laboratory records:",
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tokenCtrl,
                        decoration: const InputDecoration(
                          hintText: "Enter Token or Scan e.g. TK-C7CA9F",
                          prefixIcon: Icon(Icons.qr_code_scanner, size: 18),
                        ),
                        onSubmitted: (_) => _fetchReport(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _fetchReport,
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text("Decrypt & Access"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text("Sample: Sarah Connor CBC Token"),
                      backgroundColor: AppColors.surfaceSubtle,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: AppTypography.caption,
                      onPressed: () {
                        _tokenCtrl.text = "TK-CF164F";
                        _fetchReport();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary))),

          if (!_isLoading && _patientReport != null) ...[
            // Patient details & parameters
            AppCard(
              variant: CardVariant.standard,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_patientReport!.patientName, style: AppTypography.h2),
                          const SizedBox(height: 2),
                          Text("Report: ${_patientReport!.reportTitle} • ${_patientReport!.source}", style: AppTypography.bodySmall),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _patientReport!.token,
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text("Observed Clinical Biomarkers", style: AppTypography.sectionHeader),
                  const SizedBox(height: 12),
                  ..._patientReport!.parameters.map((p) => MetricTile(parameter: p)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Attending Physician Consultation Notes & Rx
            AppCard(
              variant: CardVariant.standard,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Physician Consultation Notes & Digital Rx", style: AppTypography.h3),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _docNameCtrl,
                    decoration: const InputDecoration(labelText: "Attending Physician Name"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: "Clinical Findings & Diagnostic Impressions"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _prescriptionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Rx: Prescription, Dosage & Follow-Up Directions",
                      hintText: "e.g. Iron supplementation 325mg daily with Vitamin C; repeat CBC in 8 weeks",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSavingNotes ? null : _saveNotes,
                    child: Center(
                      child: Text(_isSavingNotes ? "Signing & Synchronizing..." : "Sign & Synchronize to Patient Vault"),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text("Clinical Consultation Audit Trail", style: AppTypography.sectionHeader),
                  const SizedBox(height: 10),
                  if (_patientReport!.doctorNotes.isEmpty)
                    const Text("No prior physician notes recorded on this report.", style: AppTypography.bodySmall)
                  else
                    ..._patientReport!.doctorNotes.map((n) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(n.doctorName, style: AppTypography.bodyMedium),
                                  Text(n.createdAt.split('T').first, style: AppTypography.caption),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.notes, style: AppTypography.body),
                              if (n.prescription.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.medication_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Rx: ${n.prescription}",
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ------------------ Tab 2: Appointments Queue ------------------

  Widget _buildQueueTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _doctorAppointments.length,
      itemBuilder: (context, i) {
        final a = _doctorAppointments[i];
        return AppCard(
          variant: CardVariant.standard,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(a.patientName, style: AppTypography.h3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(a.status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryDark)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text("${a.date} at ${a.time} • Phone: ${a.patientPhone}", style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Text("Reason: \"${a.reason}\"", style: AppTypography.body),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (a.reportToken != null) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        _tokenCtrl.text = a.reportToken!;
                        _tabController.animateTo(0);
                        _fetchReport();
                      },
                      icon: const Icon(Icons.document_scanner_outlined, size: 14),
                      label: Text("Open Pass (${a.reportToken})"),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PopupMenuButton<String>(
                    onSelected: (val) => _updateStatus(a.id, val),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "Confirmed", child: Text("Set Confirmed")),
                      const PopupMenuItem(value: "In Consultation", child: Text("Start Consultation")),
                      const PopupMenuItem(value: "Completed", child: Text("Mark Completed")),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.surfaceSubtle,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Status Action", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ------------------ Tab 3: Manage Schedule & Availability ------------------

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Weekly Schedule Configuration Card
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text("Weekly Availability & Working Days", style: AppTypography.h3),
                    if (_currentDoctor != null) ...[
                      const Spacer(),
                      Text(
                        _currentDoctor!.name,
                        style: AppTypography.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Select the days you are available for patient consultations. ${_pairedPatients.isNotEmpty ? '${_pairedPatients.length} paired patient(s).' : ''} Days not selected are marked as OFF:",
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allWeekdays.map((day) {
                    final isAvailable = _availableDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isAvailable,
                      selectedColor: AppColors.surfaceSecondary,
                      backgroundColor: AppColors.surfaceSubtle,
                      checkmarkColor: AppColors.primaryDark,
                      labelStyle: TextStyle(
                        color: isAvailable ? AppColors.primaryDark : AppColors.textSecondary,
                        fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(color: isAvailable ? AppColors.primary : AppColors.border),
                      onSelected: (_) => _toggleDay(day),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text("Consultation Hours:", style: AppTypography.sectionHeader),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: _availableTime),
                  decoration: const InputDecoration(
                    labelText: "Daily Hours",
                    hintText: "e.g. 09:00 AM - 04:00 PM",
                    prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                  ),
                  onChanged: (val) => _availableTime = val,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vacation & Days Off Management Card
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_busy_rounded, color: AppColors.critical, size: 22),
                    SizedBox(width: 8),
                    Text("Mark Specific Days OFF / Leave", style: AppTypography.h3),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Prevent patients from booking appointments on specific dates (e.g. conferences, leave):",
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newOffDateCtrl,
                        decoration: const InputDecoration(
                          hintText: "YYYY-MM-DD e.g. 2026-11-29",
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
                      onPressed: _addOffDate,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Mark OFF"),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_offDates.isEmpty)
                  const Text("No specific days marked off. You are available according to your weekly schedule.", style: AppTypography.bodySmall)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _offDates.map((date) => Chip(
                          backgroundColor: AppColors.criticalLight,
                          side: const BorderSide(color: AppColors.criticalBorder),
                          label: Text("OFF: $date", style: const TextStyle(color: AppColors.critical, fontWeight: FontWeight.bold, fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.critical),
                          onDeleted: () {
                            setState(() => _offDates.remove(date));
                          },
                        )).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Save Schedule Button
          ElevatedButton(
            onPressed: _isSavingSchedule ? null : _saveSchedule,
            child: Center(
              child: Text(_isSavingSchedule ? "Updating Schedule..." : "Save Schedule & Availability"),
            ),
          ),
        ],
      ),
    );
  }
}

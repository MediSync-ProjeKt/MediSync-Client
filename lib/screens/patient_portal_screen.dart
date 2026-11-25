import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/clinical_disclaimer.dart';
import '../shared/widgets/health_trend_chart.dart';
import '../shared/widgets/metric_tile.dart';

class PatientPortalScreen extends StatefulWidget {
  final Function(MedicalReport)? onReportLoaded;
  final VoidCallback? onLogout;

  const PatientPortalScreen({super.key, this.onReportLoaded, this.onLogout});

  @override
  State<PatientPortalScreen> createState() => _PatientPortalScreenState();
}

class _PatientPortalScreenState extends State<PatientPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MedicalReport> _vaultReports = [];
  MedicalReport? _selectedReport;
  bool _isLoadingReports = false;
  bool _isAnalyzing = false;

  // Doctors & Appointments
  List<Doctor> _doctors = [];
  List<Pairing> _pairings = [];
  List<Appointment> _appointments = [];
  String? _selectedDoctorId;
  final _patientNameCtrl = TextEditingController(text: "Sarah Connor");
  final _phoneCtrl = TextEditingController(text: "+1 (555) 019-2834");
  final _reasonCtrl = TextEditingController(text: "Cardiovascular and metabolic review");
  final _tokenCtrl = TextEditingController();
  final String _selectedDate = "2026-11-28";
  final String _selectedTime = "10:30 AM";

  // Hospital Layer 3
  List<HospitalPairing> _hospitalPairings = [];
  Hospital? _pairedHospital;

  // AI Chat & Voice
  final _chatMsgCtrl = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isChatLoading = false;
  bool _isVoiceProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patientNameCtrl.dispose();
    _phoneCtrl.dispose();
    _reasonCtrl.dispose();
    _tokenCtrl.dispose();
    _chatMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllPatientData() async {
    setState(() => _isLoadingReports = true);
    final patient = _patientNameCtrl.text.trim();

    final reports = await ApiService.getReports(patientName: patient);
    final docs = await ApiService.getDoctors();
    final pairs = await ApiService.getPairings(patientName: patient);
    final appts = await ApiService.getAppointments(patientName: patient);
    final hosps = await ApiService.getHospitals();
    final hospPairs = await ApiService.getHospitalPairings(patientName: patient);

    setState(() {
      _vaultReports = reports;
      if (reports.isNotEmpty && _selectedReport == null) {
        _selectedReport = reports.first;
        _tokenCtrl.text = _selectedReport!.token;
        if (widget.onReportLoaded != null) widget.onReportLoaded!(_selectedReport!);
      }
      _doctors = docs;
      _pairings = pairs;
      _appointments = appts;
      _hospitalPairings = hospPairs;

      if (hosps.isNotEmpty) {
        if (hospPairs.isNotEmpty) {
          _pairedHospital = hosps.firstWhere(
            (h) => h.id == hospPairs.first.hospitalId,
            orElse: () => hosps.first,
          );
        } else {
          _pairedHospital = hosps.first;
        }
      }

      if (docs.isNotEmpty && _selectedDoctorId == null) {
        _selectedDoctorId = docs.first.id;
      }
      _isLoadingReports = false;
    });
  }

  Future<void> _generateSampleReport(String sampleType) async {
    setState(() => _isAnalyzing = true);
    final report = await ApiService.loadSampleReport(
      sampleType,
      patientName: _patientNameCtrl.text.trim(),
    );

    setState(() => _isAnalyzing = false);

    if (report != null) {
      setState(() {
        _selectedReport = report;
        _tokenCtrl.text = report.token;
        _vaultReports.insert(0, report);
      });
      if (widget.onReportLoaded != null) widget.onReportLoaded!(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ingested ${sampleType.toUpperCase()} test into Centralized Vault"),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _deleteReport(String id) async {
    final success = await ApiService.deleteReport(id);
    if (success) {
      setState(() {
        _vaultReports.removeWhere((r) => r.id == id);
        if (_selectedReport?.id == id) {
          _selectedReport = _vaultReports.isNotEmpty ? _vaultReports.first : null;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report archived from vault.")),
      );
    }
  }

  Future<void> _pairWithDoctor(Doctor doc) async {
    final pair = await ApiService.createPairing(
      patientName: _patientNameCtrl.text.trim(),
      doctorId: doc.id,
      notes: "Paired via MediSync Patient Portal",
    );
    if (pair != null) {
      final pairs = await ApiService.getPairings(patientName: _patientNameCtrl.text.trim());
      setState(() {
        _pairings = pairs;
        _selectedDoctorId = doc.id;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Paired with ${doc.name}"),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null) return;
    final success = await ApiService.bookAppointment(
      patientName: _patientNameCtrl.text.trim(),
      patientPhone: _phoneCtrl.text.trim(),
      doctorId: _selectedDoctorId!,
      date: _selectedDate,
      time: _selectedTime,
      reason: _reasonCtrl.text.trim(),
      hospitalId: _pairedHospital?.id,
      reportToken: _tokenCtrl.text.trim().isNotEmpty ? _tokenCtrl.text.trim() : null,
    );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Consultation confirmed with attending physician"), backgroundColor: AppColors.primary),
      );
      final appts = await ApiService.getAppointments(patientName: _patientNameCtrl.text.trim());
      setState(() => _appointments = appts);
    }
  }

  Future<void> _sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMsg = text.trim();
    _chatMsgCtrl.clear();

    setState(() {
      _chatHistory.add({"role": "user", "content": userMsg});
      _isChatLoading = true;
    });

    final res = await ApiService.sendChatMessage(
      message: userMsg,
      reportId: _selectedReport?.id,
      history: _chatHistory,
    );

    setState(() {
      _isChatLoading = false;
      final reply = res?['reply'] ?? res?['response'] ?? "I could not analyze your inquiry at this moment.";
      _chatHistory.add({"role": "assistant", "content": reply});
    });
  }

  Future<void> _runVoiceQuery(String query) async {
    setState(() => _isVoiceProcessing = true);
    await _sendChatMessage(query);
    setState(() => _isVoiceProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Serene, minimal tab navigation
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(icon: Icon(Icons.folder_shared_outlined, size: 18), text: "Central Vault"),
              Tab(icon: Icon(Icons.psychology_outlined, size: 18), text: "AI Assistant"),
              Tab(icon: Icon(Icons.event_available_outlined, size: 18), text: "Doctors & Visits"),
              Tab(icon: Icon(Icons.apartment_outlined, size: 18), text: "Hospital Client"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVaultTab(),
              _buildAiAssistantTab(),
              _buildDoctorsAndVisitsTab(),
              _buildHospitalClientTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------ Tab 1: Centralized Medical Vault (Layer 1) ------------------

  Widget _buildVaultTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vault Header Card
          AppCard(
            variant: CardVariant.sage,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Personal Medical Records Vault", style: AppTypography.h3),
                      const SizedBox(height: 2),
                      Text(
                        "${_patientNameCtrl.text} • MRN-78219 • Centralized Storage",
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    "${_vaultReports.length} Records",
                    style: AppTypography.badge.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Longitudinal Health Trend Visualizer (Historical line chart)
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Longitudinal Health Biomarkers", style: AppTypography.h3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("30-Day Trend", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const HealthTrendChart(
                  title: "Hemoglobin (Blood Oxygenation)",
                  unit: "g/dL",
                  minReference: 12.0,
                  maxReference: 15.5,
                  referenceRangeLabel: "12.0 – 15.5 g/dL",
                  points: [
                    HealthDataPoint(date: "Oct 12", value: 13.2, displayValue: "13.2"),
                    HealthDataPoint(date: "Oct 28", value: 12.6, displayValue: "12.6"),
                    HealthDataPoint(date: "Nov 08", value: 12.1, displayValue: "12.1"),
                    HealthDataPoint(date: "Nov 15", value: 11.4, displayValue: "11.4", isOutOfRange: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clinical Ingest Quick Actions
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ingest Verified Diagnostic Panel", style: AppTypography.sectionHeader),
                const SizedBox(height: 4),
                const Text(
                  "Import clinical laboratory documentation to parse indicators, analyze reference intervals, and synchronize to vault:",
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sampleChip("cbc", "CBC Hematology", Icons.water_drop_outlined),
                    _sampleChip("lipid", "Lipid & Cardio", Icons.favorite_border_rounded),
                    _sampleChip("metabolic", "Metabolic Glucose", Icons.science_outlined),
                    _sampleChip("thyroid", "Thyroid Profile", Icons.biotech_outlined),
                    _sampleChip("liver", "Hepatic Function", Icons.medical_services_outlined),
                    _sampleChip("kidney", "Renal Function", Icons.healing_outlined),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isAnalyzing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                    SizedBox(height: 12),
                    Text("AI extracting laboratory parameters & evaluating reference boundaries...", style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),

          // Active Selected Report Clinical Breakdown
          if (_selectedReport != null) ...[
            const ClinicalDisclaimerBanner(),
            const SizedBox(height: 16),

            // Doctor QR Access Pass Card
            AppCard(
              variant: CardVariant.tonal,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(6),
                    child: QrImageView(
                      data: "http://127.0.0.1:8000/?portal=doctor&token=${_selectedReport!.token}",
                      version: QrVersions.auto,
                      size: 96.0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Attending Physician QR Pass", style: AppTypography.h3),
                        const SizedBox(height: 3),
                        const Text(
                          "Share with your doctor during consultation for instant cryptographic chart access.",
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            "PASS: ${_selectedReport!.token}",
                            style: AppTypography.caption.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Report Biomarkers Breakdown
            AppCard(
              variant: CardVariant.standard,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(_selectedReport!.reportTitle, style: AppTypography.h2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined, size: 20, color: AppColors.textSecondary),
                        tooltip: "Archive report",
                        onPressed: () => _deleteReport(_selectedReport!.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${_selectedReport!.source} • Recorded ${_selectedReport!.createdAt.split('T').first}",
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 12),
                  Text(_selectedReport!.summaryOverview, style: AppTypography.body),
                  const Divider(),
                  const Text("Observed Biomarkers & Reference Standards", style: AppTypography.sectionHeader),
                  const SizedBox(height: 12),
                  ..._selectedReport!.parameters.map((p) => MetricTile(parameter: p)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Stored Vault Documents List
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Centralized Document Repository", style: AppTypography.h3),
                const SizedBox(height: 4),
                const Text("All clinical records synchronized across devices", style: AppTypography.bodySmall),
                const SizedBox(height: 14),
                if (_isLoadingReports)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (_vaultReports.isEmpty)
                  const Text("No clinical records currently in vault. Tap an ingest option above.", style: AppTypography.bodySmall)
                else
                  ..._vaultReports.map((r) {
                    final isSel = r.id == _selectedReport?.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.surfaceSecondary.withValues(alpha: 0.3) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? AppColors.primary : AppColors.border, width: 1),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.description_outlined, color: isSel ? Colors.white : AppColors.primary, size: 18),
                        ),
                        title: Text(r.reportTitle, style: AppTypography.bodyMedium),
                        subtitle: Text("${r.source} • ${r.createdAt.split('T').first}\nToken: ${r.token}", style: AppTypography.bodySmall),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                        onTap: () {
                          setState(() {
                            _selectedReport = r;
                            _tokenCtrl.text = r.token;
                          });
                          if (widget.onReportLoaded != null) widget.onReportLoaded!(r);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sampleChip(String type, String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 15, color: AppColors.primaryDark),
      label: Text(label),
      backgroundColor: AppColors.surfaceSubtle,
      side: const BorderSide(color: AppColors.border, width: 1),
      labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      onPressed: () => _generateSampleReport(type),
    );
  }

  // ------------------ Tab 2: AI Assistant (Ambient Intelligence) ------------------

  Widget _buildAiAssistantTab() {
    return Column(
      children: [
        // Ambient Active Record Context Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSubtle,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedReport != null
                      ? "Grounded in: ${_selectedReport!.reportTitle} (${_selectedReport!.token})"
                      : "Medical Knowledge Base Active (ADLM / Tietz Clinical Standards)",
                  style: AppTypography.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)),
                child: const Text("Non-Diagnostic", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              )
            ],
          ),
        ),

        // Conversation History Stream
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              if (_chatHistory.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.psychology_outlined, color: AppColors.primaryDark, size: 30),
                        ),
                        const SizedBox(height: 14),
                        const Text("Personal Medical AI Assistant", style: AppTypography.h2),
                        const SizedBox(height: 4),
                        const Text(
                          "Explain laboratory indicators, biological limits, or coordinate specialist appointments.",
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const Text("Suggested Inquiries", style: AppTypography.sectionHeader),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _promptChip("Explain my hemoglobin and RBC values", "What is my hemoglobin level and what does it mean?"),
                    _promptChip("What does elevated TSH indicate?", "Why is my TSH level above standard reference range?"),
                    _promptChip("Explain my kidney biomarkers", "Explain my serum creatinine and eGFR values"),
                    _promptChip("Which specialist should I visit?", "Which specialist doctor should I book an appointment with?"),
                  ],
                ),
              ] else
                ..._chatHistory.map((m) {
                  final isUser = m["role"] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isUser ? AppColors.primary : AppColors.border, width: 1),
                        boxShadow: const [AppColors.subtleShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text("MediSync Clinical Assistant", style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              ],
                            ),
                            const Divider(height: 16),
                          ],
                          Text(
                            m["content"] ?? "",
                            style: AppTypography.body.copyWith(
                              color: isUser ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              if (_isChatLoading)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text("Retrieving verified context & analyzing indicators...", style: AppTypography.caption),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Input & Voice Action Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isVoiceProcessing ? Icons.mic : Icons.mic_none_outlined,
                  color: _isVoiceProcessing ? AppColors.critical : AppColors.primary,
                ),
                tooltip: "Voice medical inquiry",
                onPressed: () => _runVoiceQuery("Explain my latest laboratory findings in simple non-diagnostic terms."),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _chatMsgCtrl,
                  decoration: const InputDecoration(
                    hintText: "Ask about your lab indicators or doctor appointments...",
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _sendChatMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                onPressed: () => _sendChatMessage(_chatMsgCtrl.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promptChip(String label, String fullQuery) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
      onPressed: () => _sendChatMessage(fullQuery),
    );
  }

  // ------------------ Tab 3: Doctors & Visits (Layer 2) ------------------

  Widget _buildDoctorsAndVisitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Paired Physicians Section
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.handshake_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text("Paired Clinical Specialists", style: AppTypography.h3),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Physicians with access to your Centralized Medical Vault:", style: AppTypography.bodySmall),
                const SizedBox(height: 14),
                ..._doctors.map((doc) {
                  final isPaired = _pairings.any((p) => p.doctorId == doc.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPaired ? AppColors.surfaceSecondary.withValues(alpha: 0.3) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isPaired ? AppColors.primary : AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.medical_services_outlined, color: AppColors.primaryDark, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc.name, style: AppTypography.bodyMedium),
                              Text("${doc.specialty} • ${doc.qualification}", style: AppTypography.bodySmall),
                              Text(doc.hospital, style: AppTypography.caption.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                        if (isPaired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(6)),
                            child: const Text("Paired ✓", style: TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        else
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () => _pairWithDoctor(doc),
                            child: const Text("Pair"),
                          )
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Booking Form
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text("Schedule Clinical Consultation", style: AppTypography.h3),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDoctorId,
                  decoration: const InputDecoration(labelText: "Attending Physician"),
                  items: _doctors
                      .map((d) => DropdownMenuItem(value: d.id, child: Text("${d.name} (${d.specialty})")))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedDoctorId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(labelText: "Consultation Reason / Clinical Symptoms"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(labelText: "Attached Medical Vault Token (Optional)"),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _bookAppointment,
                  child: const Center(child: Text("Confirm Consultation Appointment")),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appointments History
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Scheduled Clinical Appointments", style: AppTypography.h3),
                const SizedBox(height: 12),
                if (_appointments.isEmpty)
                  const Text("No active appointments scheduled.", style: AppTypography.bodySmall)
                else
                  ..._appointments.map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.doctorName, style: AppTypography.bodyMedium),
                                Text("${a.doctorSpecialty} • ${a.date} at ${a.time}", style: AppTypography.bodySmall),
                                if (a.reportToken != null) Text("Linked Chart Pass: ${a.reportToken}", style: AppTypography.caption.copyWith(color: AppColors.primary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(6)),
                              child: Text(a.status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryDark)),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ Tab 4: Hospital Client (Layer 3) ------------------

  Widget _buildHospitalClientTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Paired Hospital Profile Card
          AppCard(
            variant: CardVariant.sage,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, color: AppColors.primaryDark, size: 26),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_pairedHospital?.name ?? "MediSync Metro Health City", style: AppTypography.h2),
                            const Text("Verified Institutional Healthcare Client", style: AppTypography.caption),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: const Text("Paired Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryDark)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  "Patient Medical Record Number (MRN): ${_hospitalPairings.isNotEmpty ? _hospitalPairings.first.mrn : 'MRN-78219'}",
                  style: AppTypography.h3.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Official pathology, radiology, and discharge documentation issued by this hospital are synchronized into your Centralized Vault.",
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clinical Departments
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hospital Clinical Services & Facilities", style: AppTypography.h3),
                const SizedBox(height: 12),
                ...(_pairedHospital?.departments ?? [
                  "Comprehensive Diagnostics & Laboratory",
                  "Cardiovascular Institute",
                  "Endocrine & Metabolic Clinic",
                  "Pulmonary & Respiratory Care",
                  "Internal Medicine & Acute Care"
                ]).map((dept) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(dept, style: AppTypography.bodyMedium)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hospital Assistance & Emergency Contact
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hospital Contact & Patient Support", style: AppTypography.h3),
                const SizedBox(height: 8),
                Text("Inpatient Helpline: ${_pairedHospital?.phone ?? '+1 (800) 555-0100'}", style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text("Address: ${_pairedHospital?.address ?? '100 Healthcare Boulevard, Metro District'}", style: AppTypography.bodySmall),
                const SizedBox(height: 10),
                const Text(
                  "Reports delivered directly by hospital pathology are accessible anytime in your Centralized Medical Vault tab.",
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import '../shared/widgets/app_card.dart';

class HospitalPortalScreen extends StatefulWidget {
  const HospitalPortalScreen({super.key});

  @override
  State<HospitalPortalScreen> createState() => _HospitalPortalScreenState();
}

class _HospitalPortalScreenState extends State<HospitalPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;
  List<Appointment> _hospitalAppointments = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;

  // Report Delivery Form
  final _patientNameCtrl = TextEditingController(text: "Sarah Connor");
  final _clinicalNotesCtrl = TextEditingController(text: "Verified hospital clinical pathology evaluation");
  String _selectedReportType = "cbc";
  bool _isDelivering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHospitalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patientNameCtrl.dispose();
    _clinicalNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHospitalData() async {
    setState(() => _isLoading = true);
    final hosps = await ApiService.getHospitals();
    setState(() {
      _hospitals = hosps;
      if (hosps.isNotEmpty) {
        _selectedHospital = hosps.first;
      }
    });

    if (_selectedHospital != null) {
      await _refreshHospitalStats(_selectedHospital!.id);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _refreshHospitalStats(String hospitalId) async {
    final appts = await ApiService.getAppointments(hospitalId: hospitalId);
    final stats = await ApiService.getHospitalAnalytics(hospitalId);
    setState(() {
      _hospitalAppointments = appts;
      _analytics = stats;
    });
  }

  Future<void> _deliverReport() async {
    if (_selectedHospital == null) return;
    setState(() => _isDelivering = true);

    final success = await ApiService.deliverHospitalReport(
      hospitalId: _selectedHospital!.id,
      patientName: _patientNameCtrl.text.trim(),
      sampleType: _selectedReportType,
      clinicalNotes: _clinicalNotesCtrl.text.trim(),
    );

    setState(() => _isDelivering = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Official ${_selectedReportType.toUpperCase()} report delivered to ${_patientNameCtrl.text.trim()}'s vault"),
          backgroundColor: AppColors.primary,
        ),
      );
      _refreshHospitalStats(_selectedHospital!.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to deliver report. Check server connectivity."), backgroundColor: AppColors.critical),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(icon: Icon(Icons.local_hospital_outlined, size: 18), text: "Hospital & Roster"),
              Tab(icon: Icon(Icons.cloud_upload_outlined, size: 18), text: "Deliver Reports"),
              Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: "System Telemetry"),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildDeliverReportTab(),
                    _buildTelemetryTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_selectedHospital == null) {
      return const Center(child: Text("No hospital loaded."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hospital Profile Card
          AppCard(
            variant: CardVariant.sage,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.domain_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedHospital!.name, style: AppTypography.h2),
                          const SizedBox(height: 2),
                          Text(_selectedHospital!.address, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                          SizedBox(width: 4),
                          Text("Verified Hub", style: TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem("Helpline", _selectedHospital!.phone, Icons.phone_outlined),
                    _statItem("Registry", _selectedHospital!.email, Icons.email_outlined),
                    _statItem("Quality Score", "${_selectedHospital!.rating} / 5.0", Icons.star_border_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Department listing
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text("Active Clinical Departments", style: AppTypography.h3),
                  ],
                ),
                const SizedBox(height: 14),
                ..._selectedHospital!.departments.map((dept) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(dept, style: AppTypography.bodyMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(4)),
                            child: const Text("Operational", style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hospital switcher
          if (_hospitals.length > 1)
            AppCard(
              variant: CardVariant.standard,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Switch Institutional Administration Instance", style: AppTypography.sectionHeader),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _hospitals.map((h) {
                      final isSel = h.id == _selectedHospital!.id;
                      return ChoiceChip(
                        label: Text(h.name),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedHospital = h);
                            _refreshHospitalStats(h.id);
                          }
                        },
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildDeliverReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: AppCard(
        variant: CardVariant.standard,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text("Diagnostic Laboratory Dispatch", style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Transmit authenticated clinical pathology reports directly into the paired patient's Centralized Medical Vault:",
              style: AppTypography.bodySmall,
            ),
            const Divider(height: 24),
            TextField(
              controller: _patientNameCtrl,
              decoration: const InputDecoration(
                labelText: "Target Patient Name",
                hintText: "e.g. Sarah Connor",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            const Text("Select Clinical Pathology Panel:", style: AppTypography.sectionHeader),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _reportChip("cbc", "CBC Hematology Panel", Icons.water_drop_outlined, Colors.red),
                _reportChip("lipid", "Comprehensive Lipid", Icons.favorite_border_rounded, Colors.pink),
                _reportChip("metabolic", "Fasting Metabolic", Icons.science_outlined, Colors.teal),
                _reportChip("thyroid", "Thyroid Profile", Icons.biotech_outlined, Colors.purple),
                _reportChip("liver", "Hepatic Function (LFT)", Icons.medical_services_outlined, Colors.orange),
                _reportChip("kidney", "Renal Function (KFT)", Icons.healing_outlined, Colors.blue),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _clinicalNotesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Hospital Diagnostic Attestation Notes",
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isDelivering ? null : _deliverReport,
              child: Center(
                child: Text(
                  _isDelivering ? "Dispatching to Vault..." : "Deliver Official Report to Patient Vault",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportChip(String type, String label, IconData icon, Color iconColor) {
    final isSelected = _selectedReportType == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 15, color: isSelected ? AppColors.primaryDark : iconColor),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.surfaceSecondary,
      backgroundColor: AppColors.surfaceSubtle,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedReportType = type);
      },
    );
  }

  Widget _buildTelemetryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  "Paired Patients",
                  "${_analytics?['total_paired_patients'] ?? 1}",
                  Icons.people_outline_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  "Total Visits",
                  "${_analytics?['total_appointments'] ?? _hospitalAppointments.length}",
                  Icons.calendar_today_outlined,
                  AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  "Physicians Active",
                  "${_analytics?['available_doctors'] ?? 4}",
                  Icons.badge_outlined,
                  const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Institutional Appointments Log
          AppCard(
            variant: CardVariant.standard,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Institutional Consultations Queue", style: AppTypography.h3),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        if (_selectedHospital != null) _refreshHospitalStats(_selectedHospital!.id);
                      },
                    )
                  ],
                ),
                const SizedBox(height: 10),
                if (_hospitalAppointments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No active departmental appointments scheduled today.",
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  )
                else
                  ..._hospitalAppointments.map((a) => Container(
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
                                Text(a.patientName, style: AppTypography.bodyMedium),
                                Text("${a.doctorSpecialty} • Attending: ${a.doctorName}", style: AppTypography.bodySmall),
                                Text("${a.date} at ${a.time}", style: AppTypography.caption.copyWith(color: AppColors.primary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.status,
                                style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          ],
                        ),
                      )),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      variant: CardVariant.standard,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.measurementValueLarge.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

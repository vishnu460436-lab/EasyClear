import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';
import '../services/api_service.dart';
import '../models/report_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHomeScreen extends StatefulWidget {
  final String department;
  final String role;
  const AdminHomeScreen({
    super.key,
    required this.department,
    this.role = 'admin',
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final ApiService _apiService = ApiService();
  List<Report> _allReports = [];
  List<Report> _filteredReports = [];
  late String _selectedCategory;
  String _selectedStatus = 'all';
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'kseb',
    'water',
    'pwd',
    'police',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize selected category based on department
    if (widget.department.isNotEmpty &&
        widget.department.toUpperCase() != 'SUPER') {
      _selectedCategory = widget.department.toLowerCase();
    } else {
      _selectedCategory = 'All';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _apiService.fetchAllReports();
      setState(() {
        _allReports = reports;
        _filterReports();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _filterReports() {
    setState(() {
      _filteredReports = _allReports.where((report) {
        final matchesCategory =
            _selectedCategory == 'All' ||
            report.category.toLowerCase() == _selectedCategory.toLowerCase();

        final String statusKey = report.status.toLowerCase();
        final matchesStatus =
            _selectedStatus == 'all' || statusKey == _selectedStatus;

        return matchesCategory && matchesStatus;
      }).toList();
    });
  }

  Color get _deptColor {
    final dept = widget.department.toUpperCase();
    if (dept == 'SUPER' || dept.isEmpty) return const Color(0xFF1E3A8A);

    switch (dept) {
      case 'KSEB':
        return const Color(0xFFF59E0B);
      case 'WATER':
        return const Color(0xFF3B82F6);
      case 'PWD':
        return const Color(0xFF10B981);
      case 'POLICE':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkColor = Color(0xFF0F172A);
    const bgColor = Color(0xFFF8FAFC);

    // For stats, we filter by department if not Super Admin
    final reportsForStats =
        widget.department.toUpperCase() == 'SUPER' || widget.department.isEmpty
        ? _allReports
        : _allReports
              .where(
                (r) =>
                    r.category.toLowerCase() == widget.department.toLowerCase(),
              )
              .toList();

    final pendingCount = reportsForStats
        .where((r) => r.status == 'pending')
        .length;
    final inProgressCount = reportsForStats
        .where((r) => r.status == 'in_progress')
        .length;
    final fixedCount = reportsForStats.where((r) => r.status == 'fixed').length;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: _deptColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.department.toUpperCase() == 'SUPER' ||
                          widget.department.isEmpty
                      ? 'Admin Portal'
                      : '${widget.department.toUpperCase()} Portal',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_deptColor, _deptColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getDeptIcon(),
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),

            // Stats Overview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          'Pending',
                          pendingCount.toString(),
                          Colors.orange,
                          isSelected: _selectedStatus == 'pending',
                          onTap: () {
                            setState(() {
                              _selectedStatus = _selectedStatus == 'pending'
                                  ? 'all'
                                  : 'pending';
                              _filterReports();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          'In Progress',
                          inProgressCount.toString(),
                          Colors.blue,
                          isSelected: _selectedStatus == 'in_progress',
                          onTap: () {
                            setState(() {
                              _selectedStatus = _selectedStatus == 'in_progress'
                                  ? 'all'
                                  : 'in_progress';
                              _filterReports();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          'Fixed',
                          fixedCount.toString(),
                          Colors.green,
                          isSelected: _selectedStatus == 'fixed',
                          onTap: () {
                            setState(() {
                              _selectedStatus = _selectedStatus == 'fixed'
                                  ? 'all'
                                  : 'fixed';
                              _filterReports();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filter Section - Only show for Super Admin
            if (widget.department.toUpperCase() == 'SUPER' ||
                widget.department.isEmpty)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                              _filterReports();
                            });
                          },
                          // ... rest of the code is unchanged until the end of FilterChip
                          selectedColor: _deptColor.withValues(alpha: 0.2),
                          checkmarkColor: _deptColor,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? _deptColor : Colors.grey[600],
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? _deptColor : Colors.grey[200]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Submissions List Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  'Recent Submissions',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ),
            ),

            // Submissions List
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredReports.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No submissions found')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildAdminTaskCard(_filteredReports[index]),
                    childCount: _filteredReports.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: widget.role == 'worker'
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAnnouncementDialog,
              backgroundColor: _deptColor,
              icon: const Icon(Icons.campaign, color: Colors.white),
              label: Text(
                'Post Announcement',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  IconData _getDeptIcon() {
    switch (widget.department.toUpperCase()) {
      case 'KSEB':
        return Icons.electric_bolt_rounded;
      case 'WATER':
        return Icons.water_drop_rounded;
      case 'PWD':
        return Icons.construction_rounded;
      case 'POLICE':
        return Icons.local_police_rounded;
      case 'SUPER':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.08),
                blurRadius: isSelected ? 25 : 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28, // Slightly smaller to fit 3 columns
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11, // Slightly smaller to prevent overflow
                  color: isSelected ? color : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTaskCard(Report report) {
    final dateStr = DateFormat('dd MMM, hh:mm a').format(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      report.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.status.toUpperCase().replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(report.status),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.locationAddress ?? 'No address provided',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showReportDetailPopup(report),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[200]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              if (report.status == 'pending')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markAsInProgress(report.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Start Progress'),
                  ),
                )
              else if (report.status == 'in_progress')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markAsFixed(report.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Mark Fixed'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'fixed':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      // Try launching with external application mode first
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        throw 'Launch failed';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Google Maps. Please ensure the app is installed.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsFixed(String reportId) async {
    try {
      await _apiService.updateReportStatus(reportId, 'fixed');
      _loadData(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report marked as fixed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsInProgress(String reportId) async {
    try {
      await _apiService.updateReportStatus(reportId, 'in_progress');
      _loadData(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report marked as In Progress!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReportDetailPopup(Report report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        report.title,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (report.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      report.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 20),
                _buildDetailItem('Category', report.category.toUpperCase()),
                _buildDetailItem(
                  'Status',
                  report.status.toUpperCase().replaceAll('_', ' '),
                  color: _getStatusColor(report.status),
                ),
                _buildDetailItem('Address', report.locationAddress ?? 'N/A'),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: GoogleFonts.inter(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                if (report.latitude != null && report.longitude != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openMap(report.latitude!, report.longitude!),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('View on Google Maps'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        foregroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (report.status == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _markAsInProgress(report.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Start Progress'),
                    ),
                  )
                else if (report.status == 'in_progress')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _markAsFixed(report.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Mark Fixed'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedDept = widget.department.toUpperCase() == 'SUPER'
        ? 'OTHER'
        : widget.department.toUpperCase();
    final List<String> availableDepts = [
      'KSEB',
      'WATER',
      'PWD',
      'POLICE',
      'OTHER',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.campaign, color: _deptColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Public Announcement',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This message will be visible to all app users.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.department.toUpperCase() == 'SUPER') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDept,
                    decoration: InputDecoration(
                      labelText: 'Post As Department',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: availableDepts.map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedDept = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Power Cut Scheduled',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message Content',
                    hintText: 'Describe the details...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);
                if (!mounted) return;
                setState(() => _isLoading = true);

                try {
                  await _apiService.postAnnouncement(
                    title: titleController.text.trim(),
                    content: contentController.text.trim(),
                    department: selectedDept,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Announcement posted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _deptColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text('Yes', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

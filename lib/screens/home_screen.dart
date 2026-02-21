import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'report_screen.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'announcements_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/announcement_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _driftController;
  late AnimationController _floatController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _unreadCount = 0;
  final ApiService _apiService = ApiService();
  List<Announcement> _recentAnnouncements = [];
  bool _isLoadingAnnouncements = true;
  final Set<String> _dismissedAnnouncements = {};

  @override
  void initState() {
    super.initState();

    // Background Drift Animation
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    // Card Floating Animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Navbar scroll listener
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    _loadUnreadCount();
    _loadAnnouncements();
    _loadDismissedAnnouncements();
  }

  Future<void> _loadDismissedAnnouncements() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'dismissed_announcements_${user.id}';
    final dismissedList = prefs.getStringList(key) ?? [];

    if (mounted) {
      setState(() {
        _dismissedAnnouncements.addAll(dismissedList);
      });
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final data = await _apiService.fetchAnnouncements();
      if (mounted) {
        setState(() {
          _recentAnnouncements = data.take(5).toList();
          _isLoadingAnnouncements = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAnnouncements = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await _apiService.getUnreadNotificationsCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);
    const secondaryColor = Color(0xFF3B82F6);
    const darkColor = Color(0xFF0F172A);
    const whiteColor = Colors.white;

    return Scaffold(
      backgroundColor: whiteColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, primaryColor, _isScrolled),
      body: Stack(
        children: [
          // Background Elements
          _buildBackground(primaryColor, secondaryColor),

          // Main Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 992;
              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: 120,
                  left: isDesktop ? 80 : 24,
                  right: isDesktop ? 80 : 24,
                  bottom: 60,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(
                        context,
                        primaryColor,
                        secondaryColor,
                        darkColor,
                      )
                    : _buildMobileLayout(
                        context,
                        primaryColor,
                        secondaryColor,
                        darkColor,
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color primaryColor, Color secondaryColor) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _driftController,
          builder: (context, child) {
            return Positioned(
              top: -100 + (_driftController.value * 30),
              right: -50 + (_driftController.value * 50),
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Transform.rotate(
                angle: _driftController.value * 0.17,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.elliptical(400, 600),
                      topRight: Radius.elliptical(600, 300),
                      bottomLeft: Radius.elliptical(300, 700),
                      bottomRight: Radius.elliptical(700, 400),
                    ),
                  ),
                  child: Opacity(opacity: 0.1, child: Container()),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _driftController,
          builder: (context, child) {
            return Positioned(
              bottom: -150 + (_driftController.value * 20),
              left: -50 - (_driftController.value * 30),
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Transform.rotate(
                angle: -_driftController.value * 0.1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondaryColor, const Color(0xFF60A5FA)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.elliptical(700, 400),
                      topRight: Radius.elliptical(300, 600),
                      bottomLeft: Radius.elliptical(600, 300),
                      bottomRight: Radius.elliptical(400, 700),
                    ),
                  ),
                  child: Opacity(opacity: 0.05, child: Container()),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Color primaryColor,
    bool isScrolled,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: isScrolled
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: -0.5,
                ),
                children: const [
                  TextSpan(text: 'COMMUNITY'),
                  TextSpan(
                    text: '.',
                    style: TextStyle(color: Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (MediaQuery.of(context).size.width > 992) ...[
                  _navLink('Home', isActive: true),
                  _navLink(
                    'Announcements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnnouncementsScreen(),
                        ),
                      );
                    },
                  ),
                  _navLink(
                    'Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  _notificationIcon(context),
                  const SizedBox(width: 24),
                  _actionButton(
                    'Logout',
                    outline: true,
                    primary: primaryColor,
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.campaign_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnnouncementsScreen(),
                        ),
                      );
                    },
                  ),
                  _notificationIcon(context),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationIcon(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        _loadUnreadCount(); // Refresh count when coming back
      },
      borderRadius: BorderRadius.circular(100),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          if (_unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Color primary,
    Color secondary,
    Color dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: dark,
                      ),
                      children: [
                        const TextSpan(text: "Transforming Local "),
                        TextSpan(
                          text: "Challenges",
                          style: TextStyle(color: primary),
                        ),
                        const TextSpan(text: " into Solutions."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Join thousands of citizens making their neighborhoods better. Report issues, track progress, and build a stronger community.",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      color: const Color(0xFF64748B),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      _actionButton(
                        'Report an Issue',
                        primary: primary,
                        gradient: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _actionButton(
                        'My Submissions',
                        primary: primary,
                        outline: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 500,
                child: Stack(
                  children: [
                    _animatedFloatingCard(
                      top: 50,
                      right: 0,
                      icon: Icons.security,
                      title: "98% Resolution",
                      desc: "Prioritized concerns.",
                      delay: 0.0,
                    ),
                    _animatedFloatingCard(
                      top: 200,
                      right: 40,
                      icon: Icons.access_time_filled,
                      title: "Real-time Tracking",
                      desc: "Stay updated.",
                      delay: 0.5,
                      isBlueIcon: true,
                    ),
                    _animatedFloatingCard(
                      top: 350,
                      right: 0,
                      icon: Icons.location_on,
                      title: "Smart Mapping",
                      desc: "Precision tagging.",
                      delay: 1.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 64),
        _buildAnnouncementsSection(context, dark, primary),
        const SizedBox(height: 80),
        Text(
          "Report by Department",
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildDeptCard(
              context,
              "KSEB",
              "Electricity",
              Icons.electric_bolt_rounded,
              const Color(0xFFF59E0B),
              'kseb',
            ),
            const SizedBox(width: 20),
            _buildDeptCard(
              context,
              "PWD",
              "Roads",
              Icons.construction_rounded,
              const Color(0xFF10B981),
              'pwd',
            ),
            const SizedBox(width: 20),
            _buildDeptCard(
              context,
              "Water",
              "Leaks",
              Icons.water_drop_rounded,
              const Color(0xFF3B82F6),
              'water',
            ),
            const SizedBox(width: 20),
            _buildDeptCard(
              context,
              "Police",
              "Safety",
              Icons.local_police_rounded,
              const Color(0xFFEF4444),
              'police',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Color primary,
    Color secondary,
    Color dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: dark,
            ),
            children: [
              const TextSpan(text: "Transforming Local\n"),
              TextSpan(
                text: "Challenges",
                style: TextStyle(color: primary),
              ),
              const TextSpan(text: " into Solutions."),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Report issues and build a stronger community together.",
          style: GoogleFonts.inter(
            fontSize: 18,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 32),
        _actionButton(
          'Report an Issue',
          primary: primary,
          gradient: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _actionButton(
          'My Submissions',
          primary: primary,
          outline: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        const SizedBox(height: 48),
        _buildAnnouncementsSection(context, dark, primary),
        const SizedBox(height: 48),
        Text(
          "Quick Report",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildDeptCard(
              context,
              "KSEB",
              "Electricity",
              Icons.electric_bolt_rounded,
              const Color(0xFFF59E0B),
              'kseb',
            ),
            _buildDeptCard(
              context,
              "PWD",
              "Roads",
              Icons.construction_rounded,
              const Color(0xFF10B981),
              'pwd',
            ),
            _buildDeptCard(
              context,
              "Water",
              "Leaks",
              Icons.water_drop_rounded,
              const Color(0xFF3B82F6),
              'water',
            ),
            _buildDeptCard(
              context,
              "Police",
              "Safety",
              Icons.local_police_rounded,
              const Color(0xFFEF4444),
              'police',
            ),
          ],
        ),
      ],
    );
  }

  Widget _navLink(String text, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    String text, {
    required Color primary,
    VoidCallback? onPressed,
    bool outline = false,
    bool gradient = false,
  }) {
    if (outline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: gradient
            ? LinearGradient(colors: [primary, const Color(0xFF3B82F6)])
            : null,
        color: gradient ? null : primary,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDeptCard(
    BuildContext context,
    String name,
    String subtitle,
    IconData icon,
    Color color,
    String categoryValue,
  ) {
    final bool isDesktop = MediaQuery.of(context).size.width > 992;
    final Widget card = InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(initialCategory: categoryValue),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Expanded(child: card);
    }
    return card;
  }

  Widget _animatedFloatingCard({
    required double top,
    required double right,
    required IconData icon,
    required String title,
    required String desc,
    required double delay,
    bool isBlueIcon = false,
  }) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final value = math.sin(
          (_floatController.value * 2 * math.pi) + (delay * math.pi),
        );
        return Positioned(
          top: top + (value * 10),
          right: right,
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isBlueIcon
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFF3B82F6),
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsSection(
    BuildContext context,
    Color dark,
    Color primary,
  ) {
    if (_isLoadingAnnouncements) return const SizedBox();

    final visibleAnnouncements = _recentAnnouncements
        .where((a) => !_dismissedAnnouncements.contains(a.id))
        .toList();

    if (visibleAnnouncements.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Public Announcements",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnnouncementsScreen(),
                  ),
                );
              },
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: visibleAnnouncements.length,
            itemBuilder: (context, index) {
              final announcement = visibleAnnouncements[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            announcement.department,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM').format(announcement.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              _dismissedAnnouncements.add(announcement.id);
                            });

                            final user = AuthService().currentUser;
                            if (user != null) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final key = 'dismissed_announcements_${user.id}';
                              await prefs.setStringList(
                                key,
                                _dismissedAnnouncements.toList(),
                              );
                            }
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      announcement.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.content,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

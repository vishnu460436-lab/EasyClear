import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'report_screen.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();

    // Background Drift Animation (simulating CSS @keyframes drift)
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    // Card Floating Animation (simulating CSS @keyframes floating)
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
    // Colors from CSS
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
          // --- Background Elements ---

          // Shape 1 (Top Right)
          AnimatedBuilder(
            animation: _driftController,
            builder: (context, child) {
              return Positioned(
                top: -100 + (_driftController.value * 30),
                right: -50 + (_driftController.value * 50),
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Transform.rotate(
                  angle: _driftController.value * 0.17, // ~10 degrees
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, Color(0xFF1D4ED8)], // #1d4ed8
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
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

          // Shape 2 (Bottom Left)
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [secondaryColor, Color(0xFF60A5FA)], // #60a5fa
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.only(
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

          // --- Main Content ---
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop =
                  constraints.maxWidth > 992; // Bootstrap lg breakpoint

              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: 120, // push down for navbar
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
        child: ClipRRect(
          // Clip for backdrop filter if we wanted blur, but color opacity is simpler for perf
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand
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

              // Nav Items (Simplified for Flutter Demo)
              if (MediaQuery.of(context).size.width > 992)
                Row(
                  children: [
                    _navLink('Home', isActive: true),
                    _navLink('Dashboard'),
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
                  ],
                )
              else
                IconButton(
                  icon: Icon(Icons.person_outline, color: primaryColor),
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
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Color primary,
    Color secondary,
    Color dark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hero Content
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.only(right: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 64, // clamp(2.5rem, 6vw, 4.5rem)
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: dark,
                      letterSpacing: -1.0,
                    ),
                    children: [
                      const TextSpan(text: "Transforming Local "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                secondary.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.25, 0.25],
                            ),
                          ),
                          child: Text(
                            "Challenges",
                            style: GoogleFonts.outfit(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: " into Solutions."),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Join thousands of citizens making their neighborhoods better. Report issues, track progress, and build a stronger community together.",
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
        ),

        // Floating Cards
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 600,
            child: Stack(
              children: [
                _animatedFloatingCard(
                  top: 50,
                  right: 0,
                  icon: Icons.security,
                  title: "98% Resolution Rate",
                  desc: "Our departments prioritize your reported concerns.",
                  delay: 0.0,
                ),
                _animatedFloatingCard(
                  top: 220,
                  right: 40, // offset left
                  icon: Icons.access_time_filled,
                  title: "Real-time Tracking",
                  desc: "Stay updated on every step of the resolution process.",
                  delay: 0.5,
                  isBlueIcon: true,
                ),
                _animatedFloatingCard(
                  top: 390,
                  right: 0,
                  icon: Icons.location_on,
                  title: "Smart Mapping",
                  desc: "Precision location tagging for faster response.",
                  delay: 1.0,
                ),
              ],
            ),
          ),
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
        // Headline
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: dark,
              letterSpacing: -0.5,
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
          "Join thousands of citizens making their neighborhoods better. Report issues.",
          style: GoogleFonts.inter(
            fontSize: 18,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 60),

        // Cards
        _staticCard(
          icon: Icons.security,
          title: "98% Resolution Rate",
          desc: "Prioritized concerns.",
        ),
        const SizedBox(height: 16),
        _staticCard(
          icon: Icons.access_time_filled,
          title: "Real-time Tracking",
          desc: "Stay updated.",
        ),
        const SizedBox(height: 16),
        _staticCard(
          icon: Icons.location_on,
          title: "Smart Mapping",
          desc: "Precision tagging.",
        ),
      ],
    );
  }

  // --- Components ---

  Widget _navLink(String text, {bool isActive = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF0F172A).withValues(alpha: 0.8),
              ),
            ),
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
    // .btn-premium styles
    final borderRadius = BorderRadius.circular(100);

    if (outline) {
      return OutlinedButton(
        onPressed: onPressed ?? () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          foregroundColor: primary,
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: gradient
            ? LinearGradient(
                colors: [primary, const Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _animatedFloatingCard({
    required double top,
    required double right, // simplistic positioning
    required IconData icon,
    required String title,
    required String desc,
    required double delay,
    bool isBlueIcon = false,
  }) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Calculate a phased sine wave for floating effect
        final value = math.sin(
          (_floatController.value * 2 * math.pi) + (delay * math.pi),
        );
        final offsetY = value * 10; // 10px float range

        return Positioned(
          top: top + offsetY,
          right: right,
          child: _cardContent(icon, title, desc, isBlueIcon),
        );
      },
    );
  }

  Widget _staticCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return _cardContent(icon, title, desc, false);
  }

  Widget _cardContent(
    IconData icon,
    String title,
    String desc,
    bool isBlueIcon,
  ) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), // Glassish
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isBlueIcon
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isBlueIcon
                  ? const Color(0xFF1E3A8A)
                  : const Color(
                      0xFF3B82F6,
                    ), // Swap colors based on design variance
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

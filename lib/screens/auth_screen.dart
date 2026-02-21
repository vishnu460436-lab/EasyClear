import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _driftController;
  late AnimationController _fadeController;
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(Duration.zero); // Let build finish
    final user = _authService.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      try {
        // We need to fetch the profile to know the role
        // We can reuse a method from ApiService or AuthService if available,
        // but AuthService.login returns profile. currentUser doesn't give profile data directly.
        // We can query supabase directly here or add a method to AuthService.
        // Let's query directly to be quick, similar to login.

        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        final String role = profile['role'] ?? 'user';
        final String department = profile['department'] ?? '';

        if (!mounted) return;

        // Navigate based on role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (role == 'admin' || role == 'worker') {
                return AdminHomeScreen(department: department, role: role);
              }
              return const HomeScreen();
            },
          ),
        );
      } catch (e) {
        // If fetching profile fails (maybe network), might stay on auth screen or retry.
        // For now, let's just stop loading so they can try to login manually if needed.
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    if (_isLogin) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      result = await _authService.login(email, password);
    } else {
      result = await _authService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      final data = result['data'];
      final String role = data['role'] ?? 'user';
      final String department = data['department'] ?? '';

      // Navigate based on role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            if (role == 'admin' || role == 'worker') {
              return AdminHomeScreen(department: department, role: role);
            }
            return const HomeScreen();
          },
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Authentication failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);
    const secondaryColor = Color(0xFF3B82F6);
    const darkColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Shapes
          _buildBackgroundShapes(primaryColor, secondaryColor),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand
                    Hero(
                      tag: 'brand_logo',
                      child: Material(
                        color: Colors.transparent,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                              letterSpacing: -1.0,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? 'Welcome back! Please login to continue.'
                          : 'Create an account to join the community.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Auth Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 50,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Login' : 'Sign Up',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 32),

                            if (!_isLogin) ...[
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                hint: 'John Doe',
                              ),
                              const SizedBox(height: 20),
                            ],

                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              hint: 'name@example.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),

                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              hint: '••••••••',
                              isPassword: true,
                            ),

                            const SizedBox(height: 32),

                            _buildActionButton(
                              _isLogin ? 'Login' : 'Create Account',
                              primary: primaryColor,
                              isLoading: _isLoading,
                              onPressed: _handleSubmit,
                            ),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? "Don't have an account? "
                                      : "Already have an account? ",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _toggleAuthMode,
                                  child: Text(
                                    _isLogin ? 'Sign Up' : 'Login',
                                    style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            if (label.contains('Email') && !value.contains('@')) {
              return 'Please enter a valid email';
            }
            if (label.contains('Password') && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text, {
    required Color primary,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBackgroundShapes(Color primaryColor, Color secondaryColor) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _driftController,
          builder: (context, child) {
            return Positioned(
              top: -100 + (_driftController.value * 30),
              right: -50 + (_driftController.value * 50),
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Transform.rotate(
                angle: _driftController.value * 0.17,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
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
                  child: Opacity(opacity: 0.08, child: Container()),
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
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Transform.rotate(
                angle: -_driftController.value * 0.1,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
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
      ],
    );
  }
}

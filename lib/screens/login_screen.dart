import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  int _currentPage = 0;
  bool _isLoading = false;

  late AnimationController _beamController;

  static const Color primaryRed = Color(0xFFE53935);
  static const Color darkRed = Color(0xFFC62828);
  static const Color vividRed = Color(0xFFFF1744);
  static const Color softRed = Color(0xFFFFEBEE);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Scan Any\nDocuments',
      'type': 'scanner',
    },
    {
      'title': 'Convert Files\nto Text',
      'type': 'convert',
    },
    {
      'title': 'Easily Merge and\nManage PDFs',
      'type': 'merge',
    },
  ];

  @override
  void initState() {
    super.initState();
    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubicEmphasized,
        );
      }
    });
  }

  @override
  void dispose() {
    _beamController.dispose();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: darkRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Google Sign-In failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAuthOptionsModal({required bool defaultToSignUp}) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSignUp = defaultToSignUp;
    bool modalLoading = false;
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 30,
                offset: Offset(0, -10),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isSignUp ? 'Create EasyPDF Account' : 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isSignUp
                      ? 'Sign up to sync and back up all your scans'
                      : 'Enter your details to access your files',
                  style: const TextStyle(fontSize: 13, color: textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (isSignUp) ...[
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded,
                          color: primaryRed),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: primaryRed, width: 1.8),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: const Icon(Icons.mail_outline_rounded,
                        color: primaryRed),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: primaryRed, width: 1.8),
                    ),
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: primaryRed),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () => setModalState(
                          () => obscurePassword = !obscurePassword),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: primaryRed, width: 1.8),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 20),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [primaryRed, darkRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: modalLoading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => modalLoading = true);
                            try {
                              if (isSignUp) {
                                await AuthService.signUpWithEmail(
                                  email: emailController.text,
                                  password: passwordController.text,
                                  name: nameController.text.trim(),
                                );
                              } else {
                                await AuthService.signInWithEmail(
                                  email: emailController.text,
                                  password: passwordController.text,
                                );
                              }
                              if (mounted) {
                                final nav = Navigator.of(context);
                                nav.pop();
                                nav.pushReplacementNamed('/dashboard');
                              }
                            } on FirebaseAuthException catch (e) {
                              setModalState(() => modalLoading = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      backgroundColor: darkRed,
                                      content: Text(e.message ?? 'Auth Error')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: modalLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            isSignUp ? 'Create Account' : 'Sign In',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setModalState(() => isSignUp = !isSignUp),
                  child: Text(
                    isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Need an account? Create one',
                    style: const TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3D Realistic Flatbed Scanner (Hardware glass, perspective lid & laser)
  Widget _buildScannerArtwork() {
    return SizedBox(
      width: 280,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floor drop shadow
          Positioned(
            bottom: 8,
            child: Container(
              width: 220,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),

          // Open 3D Tilted Scanner Lid
          Positioned(
            top: 12,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0022)
                ..rotateX(-0.46),
              child: Container(
                width: 215,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF64748B), Color(0xFF1E293B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 175,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Metallic Base Console
          Positioned(
            bottom: 22,
            child: Container(
              width: 245,
              height: 115,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Illuminated Glass Scan Bed
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF334155), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Scanned Paper Document
                        Container(
                          width: 135,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  height: 3, width: 35, color: primaryRed),
                              const SizedBox(height: 4),
                              Container(
                                  height: 2,
                                  width: double.infinity,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 3),
                              Container(
                                  height: 2,
                                  width: 65,
                                  color: Colors.grey.shade300),
                            ],
                          ),
                        ),

                        // Glowing Animated Laser Line
                        AnimatedBuilder(
                          animation: _beamController,
                          builder: (context, child) {
                            return Positioned(
                              left: 6,
                              right: 6,
                              top: 6 + (_beamController.value * 48),
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: vividRed,
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                    BoxShadow(
                                      color: primaryRed.withValues(alpha: 0.8),
                                      blurRadius: 18,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Lower Hardware Console Indicators
                  Positioned(
                    bottom: 10,
                    left: 18,
                    right: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0xFF10B981), blurRadius: 6)
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                                width: 40,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(3))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: primaryRed,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('SCAN',
                              style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3D Floating Documents & Red Quick Upload Pill (Convert Files to Text)
  Widget _buildConvertArtwork() {
    return SizedBox(
      width: 280,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floor drop shadow
          Positioned(
            bottom: 10,
            child: Container(
              width: 190,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // Left 3D Floating PDF Sheet
          Positioned(
            left: 24,
            top: 28,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0016)
                ..rotateY(-0.16)
                ..rotateZ(-0.06),
              child: _buildDocCard(
                tag: 'PDF',
                accentColor: primaryRed,
                icon: Icons.picture_as_pdf_rounded,
              ),
            ),
          ),

          // Center Dynamic Sync Indicator
          Positioned(
            top: 60,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.sync_alt_rounded,
                  size: 24, color: primaryRed),
            ),
          ),

          // Right 3D Floating Text Document
          Positioned(
            right: 24,
            top: 36,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0016)
                ..rotateY(0.14)
                ..rotateZ(0.04),
              child: _buildDocCard(
                tag: 'TEXT',
                accentColor: const Color(0xFF0F172A),
                icon: Icons.article_rounded,
              ),
            ),
          ),

          // Floating Red Upload Capsule
          Positioned(
            bottom: 24,
            right: 42,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryRed.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.file_upload_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  // 3D Staggered Cascade Merge Documents
  Widget _buildMergeArtwork() {
    return SizedBox(
      width: 280,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floor drop shadow
          Positioned(
            bottom: 10,
            child: Container(
              width: 195,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // Back Doc 1
          Positioned(
            left: 32,
            top: 34,
            child: Transform.rotate(
              angle: -0.16,
              child: _buildDocCard(
                tag: 'PAGE 1',
                accentColor: const Color(0xFF94A3B8),
                icon: Icons.description_outlined,
              ),
            ),
          ),

          // Back Doc 2
          Positioned(
            right: 40,
            top: 24,
            child: Transform.rotate(
              angle: 0.12,
              child: _buildDocCard(
                tag: 'PAGE 2',
                accentColor: const Color(0xFF94A3B8),
                icon: Icons.description_outlined,
              ),
            ),
          ),

          // Hero Foreground Combined PDF Sheet
          Positioned(
            top: 42,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..scale(1.06),
              child: _buildDocCard(
                tag: 'MERGED',
                accentColor: primaryRed,
                icon: Icons.call_merge_rounded,
                isHero: true,
              ),
            ),
          ),

          // Bottom Flow Merge Ribbon
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_merge_rounded, color: primaryRed, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Unified PDF Ready',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required String tag,
    required Color accentColor,
    required IconData icon,
    bool isHero = false,
  }) {
    return Container(
      width: 108,
      height: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHero
              ? primaryRed.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner strip
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
                Icon(icon, size: 14, color: accentColor),
              ],
            ),
          ),
          // Clean skeletal text lines
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, width: 50, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Container(
                    height: 2.5,
                    width: double.infinity,
                    color: Colors.grey.shade200),
                const SizedBox(height: 4),
                Container(height: 2.5, width: 78, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                Container(height: 2.5, width: 70, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                Container(height: 2.5, width: 74, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                Container(height: 2.5, width: 44, color: Colors.grey.shade200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideGraphic(String type) {
    if (type == 'scanner') return _buildScannerArtwork();
    if (type == 'convert') return _buildConvertArtwork();
    return _buildMergeArtwork();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Top Section: Curvature Canopy with Floating 3D Artwork
          Expanded(
            flex: 12,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                ClipPath(
                  clipper: CleanCurvedClipper(),
                  child: Container(
                    height: 315,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryRed, vividRed],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildSlideGraphic(
                              _slides[index]['type'] as String),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. Middle Section: Bold Header & Dot Indicators
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _slides[_currentPage]['title'] as String,
                    key: ValueKey<int>(_currentPage),
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 7,
                      width: _currentPage == index ? 26 : 7,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? primaryRed
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Section: High-End Actions Anchored Down
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28.0, 0, 28.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Red "Continue" Button (from reference)
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [primaryRed, darkRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _showAuthOptionsModal(defaultToSignUp: false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Continue with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side:
                            BorderSide(color: Colors.grey.shade300, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: primaryRed),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(20, 20),
                                  painter: GoogleLogoPainter(),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontFamily: 'sans-serif',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Quick Sign In Link
                  TextButton(
                    onPressed: () =>
                        _showAuthOptionsModal(defaultToSignUp: false),
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                            fontFamily: 'sans-serif',
                            color: textMuted,
                            fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                                color: primaryRed, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Crisp Vector Painter for Google's Authentic 4-Color Logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - (w * 0.11));

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.4, 1.2, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.2, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.0, 1.2, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.2, 1.6, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.40, w * 0.52, h * 0.20),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CleanCurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 55);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 35,
      size.width,
      size.height - 55,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

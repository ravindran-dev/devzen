import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_input.dart';
import '../core/widgets/glass_button.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/github_provider.dart';
import '../providers/zen_provider.dart';
import 'main_navigation_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Login fields
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register fields
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  final _regGithubCtrl = TextEditingController();

  File? _selectedResumeFile;
  String _resumeFileName = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _regGithubCtrl.dispose();
    super.dispose();
  }

  bool get _canRegister =>
      _selectedResumeFile != null &&
      _regGithubCtrl.text.trim().isNotEmpty &&
      _regNameCtrl.text.trim().isNotEmpty &&
      _regEmailCtrl.text.trim().isNotEmpty &&
      _regPassCtrl.text.trim().isNotEmpty;

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      dialogTitle: 'Select your Resume',
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedResumeFile = File(result.files.single.path!);
        _resumeFileName = result.files.single.name;
      });
    }
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showSnack('Please enter your email and password');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(email, pass);

    if (mounted && success) {
      await _postAuthSetup();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted && !success) {
      _showSnack(auth.errorMessage.isNotEmpty ? auth.errorMessage : 'Login failed');
    }
  }

  Future<void> _handleRegister() async {
    if (!_canRegister) {
      _showSnack('Please fill all fields, upload resume & enter GitHub username');
      return;
    }
    if (_regPassCtrl.text.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }
    if (_regPassCtrl.text != _regConfirmPassCtrl.text) {
      _showSnack('Passwords do not match');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      fullName: _regNameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text.trim(),
      confirmPassword: _regConfirmPassCtrl.text.trim(),
      githubUsername: _regGithubCtrl.text.trim().replaceAll('@', ''),
      resumeFile: _selectedResumeFile!,
    );

    if (mounted && success) {
      await _postAuthSetup();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted && !success) {
      _showSnack(auth.errorMessage.isNotEmpty ? auth.errorMessage : 'Registration failed');
    }
  }

  Future<void> _postAuthSetup() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final github = Provider.of<GitHubProvider>(context, listen: false);
    final zen = Provider.of<ZenProvider>(context, listen: false);

    await Future.wait([
      profile.loadProfile(),
      zen.loadZenScore(),
    ]);

    if (auth.githubUsername.isNotEmpty) {
      github.loadGitHubData(auth.githubUsername);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background glows
          Positioned(
            left: -80,
            top: 80,
            child: _ambientCircle(260, AppColors.blueAccent.withOpacity(0.1)),
          ),
          Positioned(
            right: -80,
            bottom: 100,
            child: _ambientCircle(300, AppColors.purpleAccent.withOpacity(0.1)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // ─── Logo & Branding ────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blueAccent.withOpacity(0.35),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'lib/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'DevZen',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI-Powered Developer Identity Workspace',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── Tab Bar ──────────────────────────────────────────────
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [AppColors.blueAccent, AppColors.purpleAccent],
                        ),
                      ),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Register'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Tab Content ──────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _tabController.index == 0
                        ? _buildLoginTab(auth)
                        : _buildRegisterTab(auth),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Login Tab ────────────────────────────────────────────────────────────

  Widget _buildLoginTab(AuthProvider auth) {
    return GlassCard(
      key: const ValueKey('login_tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in with your GitHub email',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          GlassInput(
            hintText: 'GitHub Email',
            prefixIcon: Icons.email_outlined,
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          GlassInput(
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            controller: _loginPassCtrl,
            isPassword: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 18,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          const SizedBox(height: 28),

          if (auth.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.blueAccent))
          else
            GlassButton(
              text: 'Sign In',
              onPressed: _handleLogin,
            ),

          if (auth.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            _errorBanner(auth.errorMessage),
          ],
        ],
      ),
    );
  }

  // ─── Register Tab ─────────────────────────────────────────────────────────

  Widget _buildRegisterTab(AuthProvider auth) {
    return GlassCard(
      key: const ValueKey('register_tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create your DevZen identity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'We\'ll build your developer profile automatically',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),

          GlassInput(
            hintText: 'Full Name',
            prefixIcon: Icons.person_outline,
            controller: _regNameCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          GlassInput(
            hintText: 'GitHub Email',
            prefixIcon: Icons.email_outlined,
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          GlassInput(
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            controller: _regPassCtrl,
            isPassword: !_isPasswordVisible,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          GlassInput(
            hintText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            controller: _regConfirmPassCtrl,
            isPassword: !_isConfirmPasswordVisible,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // GitHub Username field with @ prefix
          GlassInput(
            hintText: 'GitHub Username (e.g. torvalds)',
            prefixIcon: Icons.code,
            controller: _regGithubCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Resume Upload
          _buildResumeUploadButton(),

          const SizedBox(height: 12),

          // Requirements indicator
          _buildRequirementsRow(),

          const SizedBox(height: 20),

          // Register Button — disabled until requirements met
          if (auth.isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.blueAccent),
                  SizedBox(height: 8),
                  Text(
                    'Analyzing resume & syncing GitHub...',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Opacity(
              opacity: _canRegister ? 1.0 : 0.5,
              child: GlassButton(
                text: '🚀  Analyze & Create Profile',
                onPressed: _canRegister ? _handleRegister : () {},
              ),
            ),

          if (auth.errorMessage.isNotEmpty && _tabController.index == 1) ...[
            const SizedBox(height: 12),
            _errorBanner(auth.errorMessage),
          ],
        ],
      ),
    );
  }

  Widget _buildResumeUploadButton() {
    final hasFile = _selectedResumeFile != null;
    return GestureDetector(
      onTap: _pickResume,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.greenAccent.withOpacity(0.08)
              : AppColors.surfaceLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? AppColors.greenAccent.withOpacity(0.4)
                : AppColors.glassBorder,
            width: hasFile ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.greenAccent.withOpacity(0.15)
                    : AppColors.blueAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasFile ? Icons.check_circle_outline : Icons.upload_file_outlined,
                color: hasFile ? AppColors.greenAccent : AppColors.blueAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? 'Resume Ready' : 'Upload Resume *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasFile ? AppColors.greenAccent : Colors.white,
                    ),
                  ),
                  Text(
                    hasFile ? _resumeFileName : 'PDF, DOCX or TXT • Required',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!hasFile)
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsRow() {
    final hasResume = _selectedResumeFile != null;
    final hasGithub = _regGithubCtrl.text.trim().isNotEmpty;

    return Row(
      children: [
        _reqChip('Resume', hasResume),
        const SizedBox(width: 8),
        _reqChip('GitHub Username', hasGithub),
      ],
    );
  }

  Widget _reqChip(String label, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: met ? AppColors.greenAccent : AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: met ? AppColors.greenAccent : AppColors.textMuted,
            fontWeight: met ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _ambientCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

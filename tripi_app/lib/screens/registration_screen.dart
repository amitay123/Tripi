import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';
import '../services/supabase_service.dart';
import '../providers/booking_provider.dart';
import '../models/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showSecurityError = false;

  // Password strength tracking
  bool _has8Chars = false;
  bool _hasSymbol = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final p = _passwordController.text;
    setState(() {
      _has8Chars = p.length >= 8;
      _hasSymbol = RegExp(r'[!@#$%^&*(),.?:{}|<>_\-+=\[\]\\;~/]').hasMatch(p);
      _hasNumber = RegExp(r'[0-9]').hasMatch(p);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(p);

      // Auto-hide security error once password becomes strong
      if (_strengthScore == 4) {
        _showSecurityError = false;
      }
    });
  }

  int get _strengthScore =>
      (_has8Chars ? 1 : 0) +
      (_hasSymbol ? 1 : 0) +
      (_hasNumber ? 1 : 0) +
      (_hasUppercase ? 1 : 0);

  String get _strengthLabel {
    switch (_strengthScore) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 0:
      case 1:
        return const Color(0xFFDC2626);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF10B981);
      case 4:
        return TripiColors.primary;
      default:
        return const Color(0xFFADB3B5);
    }
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }

    if (password.length < 8 || _strengthScore < 4) {
      setState(() {
        _showSecurityError = true;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (mounted) {
        if (response.session == null) {
          // This usually means email confirmation is enabled in Supabase
          setState(() {
            _isLoading = false;
            _successMessage =
                'Registration successful! Please check your email to confirm your account before signing in.';
            _errorMessage = null;
          });
          // Optionally, wait a few seconds and go back to login
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          // Sync with BookingProvider if session exists
          final supabaseUser = response.user;
          if (supabaseUser != null) {
            final userModel = models.User(
              id: supabaseUser.id,
              email: supabaseUser.email ?? '',
              name: supabaseUser.userMetadata?['full_name']?.toString() ?? name,
            );
            context.read<BookingProvider>().updateUser(userModel);
          }
          Navigator.pushReplacementNamed(context, '/explore');
        }
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.code == 'user_already_exists' ||
            e.message.contains('already registered')) {
          _errorMessage = 'This email is already registered.';
        } else {
          _errorMessage = e.message;
        }
        _successMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'אירעה שגיאה בלתי צפויה. נסה שוב מאוחר יותר.';
        _successMessage = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await SupabaseService.signInWithGoogle(intent: 'register');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSocialSignUp(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      switch (provider) {
        case 'facebook':
          await SupabaseService.signInWithFacebook(intent: 'register');
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TripiColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Tripi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: TripiColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: TripiColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'START YOUR JOURNEY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TripiColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TripiColors.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join Tripi and discover the world\'s most beautiful destinations.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TripiColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null ||
                  (_showSecurityError && _strengthScore < 4))
                _buildErrorBanner(),
              if (_successMessage != null) _buildSuccessBanner(),
              const SizedBox(height: 12),
              TripiCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(context, 'FULL NAME',
                        'Enter your full name', _nameController),
                    const SizedBox(height: 20),
                    _buildInputField(context, 'EMAIL ADDRESS',
                        'traveler@example.com', _emailController),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildStrengthGrid(),
                    const SizedBox(height: 12),
                    _buildStrengthBar(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign Up'),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR REGISTER WITH',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: TripiColors.onSurfaceVariant,
                                  letterSpacing: 1,
                                ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            context,
                            Icons.g_mobiledata,
                            'Google',
                            onTap: _isLoading ? null : _handleGoogleSignUp,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSocialButton(
                            context,
                            Icons.facebook,
                            'Facebook',
                            onTap: () => _handleSocialSignUp('facebook'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TripiColors.onSurfaceVariant,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Sign In',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TripiColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border:
            const Border(left: BorderSide(color: Color(0xFFE65100), width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_read_outlined, color: Color(0xFFE65100)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check Your Email',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                ),
                Text(
                  _successMessage!,
                  style: TextStyle(
                      color: const Color(0xFFE65100).withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final bool isSecurityInfo = _errorMessage == null;
    final String message = isSecurityInfo
        ? 'Password must meet all security requirements'
        : _errorMessage!;
    final IconData icon = isSecurityInfo ? Icons.security : Icons.error;

    // Colors for Security (Orange) vs Error (Red)
    final Color bgColor =
        isSecurityInfo ? const Color(0xFFFFF3E0) : const Color(0xFFF8E8E8);
    final Color accentColor =
        isSecurityInfo ? const Color(0xFFE65100) : const Color(0xFFB00020);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASSWORD',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TripiColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: const TextStyle(color: TripiColors.onSurface),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: TripiColors.onSurfaceVariant),
            filled: true,
            fillColor: TripiColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: TripiColors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 4.2,
      children: [
        _buildCriteriaChip('8+ Characters', _has8Chars),
        _buildCriteriaChip('1 Symbol', _hasSymbol),
        _buildCriteriaChip('1 Number', _hasNumber),
        _buildCriteriaChip('Uppercase', _hasUppercase),
      ],
    );
  }

  Widget _buildCriteriaChip(String label, bool met) {
    return Container(
      decoration: BoxDecoration(
        color: TripiColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? TripiColors.primary : const Color(0xFFADB3B5),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: met ? TripiColors.primary : const Color(0xFF5A6062),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STRENGTH',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: _strengthColor,
              ),
            ),
            Text(
              _passwordController.text.isEmpty ? '' : _strengthLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: _strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 6,
            width: double.infinity,
            color: TripiColors.surfaceContainerHigh,
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  alignment: Alignment.centerLeft,
                  widthFactor: _passwordController.text.isEmpty
                      ? 0
                      : _strengthScore / 4.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _strengthColor,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context, String label, String hint,
      TextEditingController controller,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TripiColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: TripiColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: TripiColors.onSurfaceVariant),
            filled: true,
            fillColor: TripiColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap}) {
    final bool isGoogle = label.toLowerCase().contains('google');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: TripiColors.outlineVariant.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGoogle)
                Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  height: 20,
                  width: 20,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Color(0xFF4285F4)),
                )
              else if (label.toLowerCase().contains('facebook'))
                const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24)
              else
                const Icon(Icons.apple, color: Colors.black, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: TripiColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

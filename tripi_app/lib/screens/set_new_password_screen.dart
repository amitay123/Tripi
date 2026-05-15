import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/tripi_colors.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _errorMessage;
  String? _successMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Password strength tracking
  bool _has8Chars = false;
  bool _hasSymbol = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final p = _passwordController.text;
    setState(() {
      _has8Chars = p.length >= 8;
      _hasSymbol = RegExp(r'[!@#$%^&*(),.?:{}|<>_\-+=\[\]\\;~/]').hasMatch(p);
      _hasNumber = RegExp(r'[0-9]').hasMatch(p);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(p);
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

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (password.length < 8 || _strengthScore < 4) {
      setState(() =>
          _errorMessage = 'Password must meet all security requirements.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      setState(() {
        _isLoading = false;
        _successMessage =
            'Password updated successfully! Redirecting to login...';
        _errorMessage = null;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _successMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      body: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TripiColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: TripiColors.primary),
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/'),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Secure Your Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: TripiColors.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a strong password to complete your recovery.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: TripiColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_errorMessage != null) _buildErrorBanner(),
                    if (_successMessage != null) _buildSuccessBanner(),
                    const SizedBox(height: 12),
                    _buildInputField(
                        'NEW PASSWORD',
                        _passwordController,
                        _showPassword,
                        (v) => setState(() => _showPassword = v)),
                    const SizedBox(height: 16),
                    _buildStrengthGrid(),
                    const SizedBox(height: 12),
                    _buildStrengthBar(),
                    const SizedBox(height: 24),
                    _buildInputField('CONFIRM PASSWORD', _confirmController,
                        _showConfirm, (v) => setState(() => _showConfirm = v)),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      bool obscure, Function(bool) toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: TripiColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !obscure,
          style: GoogleFonts.inter(color: TripiColors.onSurface),
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
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  color: TripiColors.onSurfaceVariant),
              onPressed: () => toggle(!obscure),
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
          Icon(met ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: met ? TripiColors.primary : TripiColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: met ? TripiColors.primary : TripiColors.onSurfaceVariant,
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
            Text('STRENGTH',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _strengthColor)),
            Text(_passwordController.text.isEmpty ? '' : _strengthLabel,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _strengthColor)),
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
                  widthFactor: _passwordController.text.isEmpty
                      ? 0
                      : _strengthScore / 4.0,
                  child: Container(color: _strengthColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleUpdatePassword,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: TripiColors.primary,
        foregroundColor: Colors.white,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Text('Update Password'),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border:
            const Border(left: BorderSide(color: Color(0xFFDC2626), width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626)))),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border:
            const Border(left: BorderSide(color: Color(0xFF16A34A), width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(_successMessage!,
                  style: const TextStyle(color: Color(0xFF16A34A)))),
        ],
      ),
    );
  }
}

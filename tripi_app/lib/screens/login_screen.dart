import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/tripi_colors.dart';
import '../services/supabase_service.dart';
import '../providers/booking_provider.dart';
import '../models/models.dart' as models;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignInLoading = false;
  bool _isForgotInProgress = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleSignIn() async {
    if (_isForgotInProgress) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email and password';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isSignInLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    debugPrint('STATE: _isSignInLoading set to true');

    try {
      debugPrint('Attempting login for: $email');
      await SupabaseService.signIn(email: email, password: password);
      debugPrint('Login successful');
      
      // Sync with BookingProvider
      if (mounted) {
        final supabaseUser = SupabaseService.currentUser;
        if (supabaseUser != null) {
          context.read<BookingProvider>().updateUser(supabaseUser);
        }
        Navigator.pushReplacementNamed(context, '/explore');
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      String errorMsg = e.toString();
      if (errorMsg.contains('Email not confirmed')) {
        errorMsg = 'Your email has not been confirmed yet. Please check your inbox for the confirmation link and try again.';
      } else if (errorMsg.contains('Invalid login credentials')) {
        errorMsg = 'Invalid email or password. Please try again.';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _successMessage = null;
        _isSignInLoading = false;
      });
      debugPrint('STATE: _isSignInLoading set to false');
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_isSignInLoading) return;
    
    // Unfocus to prevent focus shifts from looking like a button click
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isForgotInProgress = true;
      _errorMessage = null;
      _successMessage = null;
    });
    debugPrint('STATE: _isForgotInProgress set to true');

    try {
      /* 
      // 1. Check if user exists first (requested security/UX requirement)
      // Note: This is temporarily disabled because the profiles table is out of sync.
      final exists = await SupabaseService.isUserRegistered(email);
      
      if (!exists) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid email or password. Please try again.';
            _successMessage = null;
          });
        }
        return;
      }
      */

      await SupabaseService.resetPassword(
        email: email,
        redirectTo: 'https://tripi-app-af1ad.web.app/#/set-new-password',
      );
      
      if (mounted) {
        setState(() {
          _successMessage = 'Password reset email sent! Check your inbox.';
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Forgot password error: $e');
      if (mounted) {
        setState(() {
          if (e is AuthApiException && (e.code == 'over_email_send_rate_limit' || e.statusCode == '429')) {
            _successMessage = 'Password reset email sent! Check your inbox.';
            _errorMessage = null;
          } else {
            _errorMessage = e.toString();
            _successMessage = null;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isForgotInProgress = false;
        });
        debugPrint('STATE: _isForgotInProgress set to false');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSignInLoading) return;
    setState(() {
      _isSignInLoading = true;
      _errorMessage = null;
    });
    try {
      await SupabaseService.signInWithGoogle(intent: 'login');
      // In Web OAuth, the page redirects, so we don't reach here
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Google Sign In failed. Please try again.';
          _isSignInLoading = false;
        });
      }
    }
  }

  Future<void> _handleSocialSignIn(String provider) async {
    if (_isSignInLoading) return;
    setState(() {
      _isSignInLoading = true;
      _errorMessage = null;
    });
    try {
      switch (provider) {
        case 'facebook':
          await SupabaseService.signInWithFacebook(intent: 'login');
          break;
      }
    } catch (e) {
      debugPrint('Social Sign In Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign In failed. Please try again.';
          _isSignInLoading = false;
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
        automaticallyImplyLeading: false,
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Welcome back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TripiColors.onSurface,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Sign in to continue your adventure.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TripiColors.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null) _buildErrorBanner(),
            if (_successMessage != null) _buildSuccessBanner(),
            const SizedBox(height: 32),
            _buildInputField(
              context,
              'EMAIL ADDRESS',
              'traveler@example.com',
              _emailController,
              Icons.email_outlined,
              hasError: _errorMessage != null,
            ),
            const SizedBox(height: 24),
            _buildInputField(
              context,
              'PASSWORD',
              '••••••••',
              _passwordController,
              Icons.lock_outline,
              isPassword: true,
              hasError: _errorMessage != null,
              suffix: TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _isForgotInProgress
                    ? const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TripiColors.primary,
                        ),
                      )
                    : Text(
                        'Forgot?',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: TripiColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            IgnorePointer(
              ignoring: _isForgotInProgress,
              child: ElevatedButton(
                onPressed: _isSignInLoading ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSignInLoading)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else ...[
                      const Text('Sign In'),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TripiColors.onSurfaceVariant,
                        ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    Icons.g_mobiledata,
                    'Google',
                    onTap: _isSignInLoading ? null : _handleGoogleSignIn,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSocialButton(
                    Icons.facebook,
                    'Facebook',
                    onTap: () => _handleSocialSignIn('facebook'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 64),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TripiColors.onSurfaceVariant,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TripiColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E8E8),
        borderRadius: BorderRadius.circular(16),
        border:
            const Border(left: BorderSide(color: Color(0xFFB00020), width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error, color: Color(0xFFB00020)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Authentication Failed',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFB00020)),
                ),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                      color: const Color(0xFFB00020).withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
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
                      color: const Color(0xFFE65100).withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    bool hasError = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TripiColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
            ),
            if (suffix != null) suffix,
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon,
                color: hasError
                    ? const Color(0xFFB00020)
                    : TripiColors.onSurfaceVariant),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFB00020)
                    : TripiColors.outlineVariant.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFB00020) : TripiColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label, {VoidCallback? onTap}) {
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
            border:
                Border.all(color: TripiColors.outlineVariant.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
                )
              else if (label.toLowerCase().contains('facebook'))
                const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24)
              else
                const Icon(Icons.apple, color: Colors.black, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: TripiColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

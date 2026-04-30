import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';
import '../services/supabase_service.dart';
import '../providers/booking_provider.dart';
import '../models/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await SupabaseService.signIn(email: email, password: password);
      
      if (mounted) {
        final supabaseUser = response.user;
        if (supabaseUser != null) {
          final userModel = models.User(
            id: supabaseUser.id,
            email: supabaseUser.email ?? '',
            name: supabaseUser.userMetadata?['full_name']?.toString() ?? 'Traveler',
          );
          context.read<BookingProvider>().updateUser(userModel);
        }
        Navigator.pushReplacementNamed(context, '/explore');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Invalid login credentials') 
            ? 'Invalid email or password' 
            : e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email to reset password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await SupabaseService.resetPassword(email);
      setState(() {
        _successMessage = 'Reset link sent! Please check your email.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              // Logo/Brand Section
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: TripiColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: TripiColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tripi',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: TripiColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Plan your next adventure with ease.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TripiColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 48),
              if (_errorMessage != null) _buildErrorBanner(),
              if (_successMessage != null) _buildSuccessBanner(),
              const SizedBox(height: 12),
              TripiCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(context, 'EMAIL ADDRESS', 'hello@example.com', _emailController),
                    const SizedBox(height: 24),
                    _buildPasswordField(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          'Forgot?',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: TripiColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      'Sign Up',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TripiColors.primary,
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
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E8E8),
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFFB00020), width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB00020)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFB00020), fontWeight: FontWeight.w500),
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
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFF2E7D32), width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage!,
              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String label, String hint, TextEditingController controller) {
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
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: TripiColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
        ),
      ],
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
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: TripiColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: TripiColors.onSurfaceVariant),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
      ],
    );
  }
}

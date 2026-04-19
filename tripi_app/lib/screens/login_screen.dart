import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tripi_colors.dart';
import '../providers/booking_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hasError = false;

  void _handleSignIn() {
    final route = context.read<BookingProvider>().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
    if (route != null) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: TripiColors.primary),
        title: Text(
          'AZURE NOMAD',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TripiColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
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
            if (_hasError) _buildErrorBanner(),
            const SizedBox(height: 32),
            _buildInputField(
              context,
              'EMAIL ADDRESS',
              'traveler@voyage.com',
              _emailController,
              Icons.email_outlined,
              hasError: _hasError,
            ),
            const SizedBox(height: 24),
            _buildInputField(
              context,
              'PASSWORD',
              '••••••••',
              _passwordController,
              Icons.lock_outline,
              isPassword: true,
              hasError: _hasError,
              suffix: Text(
                'Forgot?',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TripiColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _handleSignIn,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Sign In'),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20),
                ],
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
                Expanded(child: _buildSocialButton(Icons.g_mobiledata, 'Google')),
                const SizedBox(width: 16),
                Expanded(child: _buildSocialButton(Icons.apple, 'Apple')),
              ],
            ),
            const SizedBox(height: 64),
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
                    'Create Account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TripiColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
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
        border: const Border(left: BorderSide(color: Color(0xFFB00020), width: 4)),
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB00020)),
                ),
                Text(
                  'Invalid email or password. Please try again.',
                  style: TextStyle(color: const Color(0xFFB00020).withOpacity(0.8)),
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
            prefixIcon: Icon(icon, color: hasError ? const Color(0xFFB00020) : TripiColors.onSurfaceVariant),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFB00020) : TripiColors.outlineVariant.withOpacity(0.2),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TripiColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: TripiColors.onSurface),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';
import '../providers/booking_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  void _handleSignUp() {
    setState(() {
      _errorMessage = null;
    });

    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
      final email = _emailController.text.trim();
      final success = context.read<BookingProvider>().register(
            _nameController.text.trim(),
            email,
          );
      
      if (success) {
        Navigator.pushReplacementNamed(context, '/explore');
      } else {
        setState(() {
          if (email == 'admin@tripi.com') {
            _errorMessage = 'This email address is already in use by the system administrator. Please use a different email.';
          } else {
            _errorMessage = 'Registration failed. This email may already be registered.';
          }
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please fill in all required fields.';
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: TripiColors.primary.withOpacity(0.1),
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
              const SizedBox(height: 32),
              if (_errorMessage != null) _buildErrorBanner(),
              const SizedBox(height: 24),
              TripiCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(context, 'FULL NAME', 'Enter your full name', _nameController),
                    const SizedBox(height: 20),
                    _buildInputField(context, 'EMAIL ADDRESS', 'hello@example.com', _emailController),
                    const SizedBox(height: 20),
                    _buildInputField(context, 'PASSWORD', 'Min. 8 characters', _passwordController, isPassword: true),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR REGISTER WITH',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                        Expanded(child: _buildSocialButton(context, Icons.g_mobiledata, 'Google')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSocialButton(context, Icons.apple, 'Apple')),
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
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFB00020), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String label, String hint, TextEditingController controller, {bool isPassword = false}) {
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

  Widget _buildSocialButton(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: TripiColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: TripiColors.onSurface),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TripiColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

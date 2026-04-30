import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/tripi_colors.dart';
import '../widgets/tripi_card.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both fields.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.updatePassword(password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully! Please sign in with your new password.')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
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
      appBar: AppBar(
        title: const Text('Set New Password', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Create a strong password to secure your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TripiColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null) _buildErrorBanner(),
              const SizedBox(height: 12),
              TripiCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildPasswordField('NEW PASSWORD', _passwordController),
                    const SizedBox(height: 24),
                    _buildPasswordField('CONFIRM PASSWORD', _confirmController),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdatePassword,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Update Password'),
                    ),
                  ],
                ),
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

  Widget _buildPasswordField(String label, TextEditingController controller) {
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

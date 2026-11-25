import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../onboarding/onboarding_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _institutionController = TextEditingController();
  final _countryController = TextEditingController();

  String _selectedRole = 'Student (UG/PG)';
  bool _termsAccepted = true;
  bool _isLoading = false;
  String? _errorMessage;

  final ResWaveAuthService _authService = ResWaveAuthService.instance;

  final List<String> _roles = [
    'Student (UG/PG)',
    'PhD Scholar',
    'Professor / Faculty',
    'Researcher',
    'Independent Researcher',
    'Other'
  ];

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      setState(() => _errorMessage =
          'You must accept the Terms of Service & Privacy Policy');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        country: _countryController.text.trim(),
        institution: _institutionController.text.trim(),
      );
      if (mounted) {
        // Route to progressive 10-step onboarding (Section E)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => OnboardingScreen(user: user)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ResWaveAuthService.messageForError(
            e,
            operation: 'create your account',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join ResWave',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Start your academic research journey across any field.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *', hintText: 'e.g. Maya Lin'),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'name@institution.edu'),
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration:
                      const InputDecoration(labelText: 'Academic Role *'),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedRole = val ?? _selectedRole),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _institutionController,
                  decoration: const InputDecoration(
                      labelText: 'Institution / Organisation',
                      hintText: 'e.g. Oxford University'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                      labelText: 'Country *', hintText: 'e.g. United Kingdom'),
                  validator: (v) => Validators.validateRequired(v, 'Country'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: 'Password (min 8 chars) *',
                      hintText: '••••••••'),
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      activeColor: AppColors.primaryTeal,
                      onChanged: (val) =>
                          setState(() => _termsAccepted = val ?? true),
                    ),
                    const Expanded(
                      child: Text(
                        'I accept ResWave Terms of Service & Privacy Policy (v3.0)',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.darkTextSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                    ),
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

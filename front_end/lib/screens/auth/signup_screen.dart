import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String _passwordStrength = '';
  Color _strengthColor = AppColors.mediumGray;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _updatePasswordStrength() {
    final strengthEnum = Validators.getPasswordStrength(_passwordController.text);
    final strength = strengthEnum.name;
    setState(() {
      _passwordStrength = strength;
      _strengthColor = _getStrengthColor(strength);
    });
  }

  Color _getStrengthColor(String strength) {
    switch (strength) {
      case 'Strong':
        return AppColors.successGreen;
      case 'Medium':
        return AppColors.warningOrange;
      case 'Weak':
        return AppColors.emergencyRed;
      default:
        return AppColors.mediumGray;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Username',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.mediumGray),
                    validator: Validators.validateUsername,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.mediumGray),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.mediumGray),
                    showTogglePassword: true,
                    validator: Validators.validatePassword,
                  ),
                  if (_passwordStrength.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _getStrengthValue(_passwordStrength),
                            backgroundColor: AppColors.tertiaryDark,
                            valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _passwordStrength,
                          style: AppTextStyles.bodySmall.copyWith(color: _strengthColor),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.mediumGray),
                    showTogglePassword: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 32),
                  GradientButton(
                    text: 'Create Account',
                    onPressed: _agreedToTerms ? _handleSignup : null,
                    isLoading: _isLoading,
                    gradientColors: const [AppColors.pinkPrimary, AppColors.purplePrimary],
                  ),
                  const SizedBox(height: 20),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.pinkPrimary, AppColors.purplePrimary]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.pinkPrimary.withAlpha(76),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 24),
        Text('Create Account', style: AppTextStyles.header1),
        const SizedBox(height: 8),
        Text(
          'Start your health journey today',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.pinkPrimary;
            }
            return AppColors.tertiaryDark;
          }),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: AppTextStyles.bodyMedium,
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pinkPrimary),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pinkPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
        child: Text.rich(
          TextSpan(
            text: 'Already have an account? ',
            style: AppTextStyles.bodyMedium,
            children: [
              TextSpan(
                text: 'Login',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.pinkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getStrengthValue(String strength) {
    switch (strength) {
      case 'Strong':
        return 1.0;
      case 'Medium':
        return 0.66;
      case 'Weak':
        return 0.33;
      default:
        return 0.0;
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }
}

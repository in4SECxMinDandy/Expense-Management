import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService.register(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Registration failed (min 6 chars for password)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getPurpleGradient(isDark)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: AppTheme.headingXL.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Join SpendWise today',
                    style: AppTheme.bodyM.copyWith(color: Colors.white70),
                  ),

                  const SizedBox(height: AppTheme.spaceXXL),

                  // Register Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurface(isDark).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CupertinoTextField(
                          controller: _nameController,
                          placeholder: 'Full Name',
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceElevated
                                : AppTheme.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                          ),
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceM),

                        CupertinoTextField(
                          controller: _emailController,
                          placeholder: 'Email',
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceElevated
                                : AppTheme.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                          ),
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(isDark),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppTheme.spaceM),

                        CupertinoTextField(
                          controller: _passwordController,
                          placeholder: 'Password',
                          obscureText: true,
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceElevated
                                : AppTheme.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                          ),
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(isDark),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppTheme.spaceM),
                          Text(
                            _errorMessage!,
                            style: AppTheme.bodyS.copyWith(
                              color: AppTheme.expenseRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: AppTheme.spaceXL),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

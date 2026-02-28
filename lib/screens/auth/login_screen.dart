import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password (min 6 chars)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getPurpleGradient(isDark)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard_fill,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),

                  Text(
                    'SpendWise',
                    style: AppTheme.headingXL.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Smart Expense Tracking',
                    style: AppTheme.bodyM.copyWith(color: Colors.white70),
                  ),

                  const SizedBox(height: AppTheme.spaceXXL),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurface(isDark).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login',
                          style: AppTheme.headingM.copyWith(
                            color: AppTheme.getTextPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),

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
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Sign In'),
                        ),

                        const SizedBox(height: AppTheme.spaceM),

                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Don\'t have an account? Sign Up'),
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

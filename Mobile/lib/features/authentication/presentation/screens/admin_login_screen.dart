import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

enum SocialProvider { google, apple }

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSocialLogin(SocialProvider provider) {
    setState(() => _isLoading = true);
    final authNotifier = ref.read(authControllerProvider.notifier);
    
    final successCallback = () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.goNamed('admin-dashboard');
      }
    };

    final errorCallback = (String error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };

    if (provider == SocialProvider.google) {
      authNotifier.loginWithGoogle(
        expectedRole: UserRole.admin,
        onSuccess: successCallback,
        onError: errorCallback,
      );
    } else {
      authNotifier.loginWithApple(
        expectedRole: UserRole.admin,
        onSuccess: successCallback,
        onError: errorCallback,
      );
    }
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final input = _emailController.text.trim();
      String resolvedEmail = input;

      // Check if it's a username (doesn't contain a standard domain dot, or starts with @)
      final hasStandardDomain = input.contains('.') && input.indexOf('.') > input.indexOf('@');
      if (!hasStandardDomain) {
        // Strip leading '@' if present
        String cleanUsername = input.toLowerCase();
        if (cleanUsername.startsWith('@')) {
          cleanUsername = cleanUsername.substring(1);
        }
        resolvedEmail = '$cleanUsername@nationalacademy.internal';
      }

      ref.read(authControllerProvider.notifier).login(
            email: resolvedEmail,
            password: _passwordController.text,
            expectedRole: UserRole.admin,
            onSuccess: () {
              if (mounted) {
                setState(() => _isLoading = false);
                context.goNamed('admin-dashboard');
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Heading
                Text(
                  'Admin Portal',
                  style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back! Sign in to manage your academy.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 48),

                // Email Field
                Text(
                  'Username or Email Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Enter your username or email',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textLight),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Username or Email is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed('forgot-password'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onLogin(),
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 40),

                // Login Button
                TactileButton(
                  onTap: _isLoading ? null : _onLogin,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Or continue with',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),
                // Social buttons row
                Row(
                  children: [
                    // Google Sign-In Button
                    Expanded(
                      child: TactileButton(
                        onTap: _isLoading ? null : () => _onSocialLogin(SocialProvider.google),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          ),
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                            height: 18,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                          ),
                          label: Text(
                            'Google',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _onSocialLogin(SocialProvider.google),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Apple Sign-In Button
                    Expanded(
                      child: TactileButton(
                        onTap: _isLoading ? null : () => _onSocialLogin(SocialProvider.apple),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          ),
                          icon: Icon(
                            Icons.apple_rounded,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                          label: Text(
                            'Apple',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _onSocialLogin(SocialProvider.apple),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

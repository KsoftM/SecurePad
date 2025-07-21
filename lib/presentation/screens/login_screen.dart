import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (_isLogin) {
        await auth.signIn(_emailController.text, _passwordController.text);
      } else {
        await auth.register(_emailController.text, _passwordController.text);
      }
      if (mounted) {
        setState(() => _error = null);
      }
    } on Exception catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.toString().contains('email-already-in-use')) {
        message = 'Email already in use.';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Invalid email address.';
      } else if (e.toString().contains('weak-password')) {
        message = 'Password should be at least 6 characters.';
      } else if (e.toString().contains('user-not-found')) {
        message = 'No user found for that email.';
      } else if (e.toString().contains('wrong-password')) {
        message = 'Wrong password provided.';
      }
      if (mounted) {
        setState(() => _error = message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Unknown error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v != null && v.contains('@')
                      ? null
                      : 'Enter a valid email',
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Min 6 chars',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : () => _submit(context),
                  child: Text(_isLogin ? 'Login' : 'Register'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin
                      ? 'No account? Register'
                      : 'Have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

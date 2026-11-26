import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const String kCatcherBaseUrl = 'https://lab13v25.requestcatcher.com';

void main() {
  runApp(const DioBackendLabApp());
}

class BackendClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kCatcherBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<String> postAction(String path, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(path, data: payload);
      return 'Надіслано на $kCatcherBaseUrl$path (код ${response.statusCode})';
    } on DioException catch (e) {
      return 'Помилка Dio: ${e.message ?? 'невідома помилка'}';
    }
  }
}

class DioBackendLabApp extends StatelessWidget {
  const DioBackendLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2E5BFF));

    return MaterialApp(
      title: 'Лаб 13 — Dio та RequestCatcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
      },
    );
  }
}

bool _isValidEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}

String? _validateRequired(String? value, String message) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Введіть пароль';
  if (value.length < 7) return 'Пароль має містити не менше 7 символів';
  return null;
}

String? _validateLoginOrEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Введіть логін або електронну пошту';
  }
  final trimmed = value.trim();
  if (trimmed.contains('@') && !_isValidEmail(trimmed)) {
    return 'Некоректний формат електронної пошти';
  }
  if (!trimmed.contains('@') && trimmed.length < 3) {
    return 'Логін має містити мінімум 3 символи';
  }
  return null;
}

/// 1. АВТОРИЗАЦІЯ (Login)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _client = BackendClient();
  bool _isSending = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final status = await _client.postAction('/login', {
      'action': 'login',
      'login': _loginController.text.trim(),
      'password': _passwordController.text,
    });

    if (!mounted) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.login_rounded, size: 56),
              const SizedBox(height: 12),
              Text(
                'Авторизація',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Логін або email',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validateLoginOrEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль (мін. 7 символів)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: _validatePassword,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/reset'),
                  child: const Text('Reset Password'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSending ? null : _onLogin,
                child: Text(_isSending ? 'Надсилання...' : 'Login'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. РЕЄСТРАЦІЯ (Sign up)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _client = BackendClient();
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final status = await _client.postAction('/signup', {
      'action': 'signup',
      'username': _nameController.text.trim(),
      'login': _loginController.text.trim(),
      'password': _passwordController.text,
    });

    if (!mounted) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                'Реєстрація',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ім’я користувача',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => _validateRequired(v, 'Введіть ім’я користувача'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Логін або email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: _validateLoginOrEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль (мін. 7 символів)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSending ? null : _onSignUp,
                child: Text(_isSending ? 'Надсилання...' : 'Sign up'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Назад до Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3. ВІДНОВЛЕННЯ ПАРОЛЮ (Reset / Reset Password)
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _client = BackendClient();
  bool _isSending = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final status = await _client.postAction('/reset', {
      'action': 'reset_password',
      'contact': _contactController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset_rounded, size: 56),
              const SizedBox(height: 12),
              Text(
                'Відновлення паролю',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Логін або електронна пошта',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: _validateLoginOrEmail,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSending ? null : _onReset,
                child: Text(_isSending ? 'Надсилання...' : 'Reset'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Повернутися до Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
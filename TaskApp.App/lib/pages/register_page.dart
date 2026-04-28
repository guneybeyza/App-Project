import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:taskapp_app/widgets/shared_widgets.dart';

const String _apiBaseUrl = 'http://localhost:5062';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Tüm alanları doldurun.', isError: true);
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showSnack('Şifreler uyuşmuyor!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/User'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        _showSnack('Kayıt başarılı! 🎉 Lütfen giriş yapın.');
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        var errorMsg = 'Kayıt başarısız oldu.';
        try {
          errorMsg = jsonDecode(response.body)['message'] ?? errorMsg;
        } catch (_) {}
        _showSnack(errorMsg, isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnack('Bağlantı hatası: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Card(
                  elevation: 24,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6584), Color(0xFFFF8E53)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6584).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Hesap Oluştur',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A2E),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ücretsiz hesabınızı oluşturun',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        StyledTextField(
                          controller: _nameController,
                          label: 'Ad Soyad',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 14),
                        StyledTextField(
                          controller: _emailController,
                          label: 'E-posta',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        StyledTextField(
                          controller: _passwordController,
                          label: 'Şifre',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePw,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePw
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePw = !_obscurePw),
                          ),
                        ),
                        const SizedBox(height: 14),
                        StyledTextField(
                          controller: _confirmController,
                          label: 'Şifre Tekrar',
                          icon: Icons.lock_reset_rounded,
                          obscureText: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Kayıt Ol',
                          onPressed: _isLoading ? null : _register,
                          isLoading: _isLoading,
                          colors: const [Color(0xFFFF6584), Color(0xFFFF8E53)],
                          glowColor: const Color(0xFFFF6584),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Zaten hesabın var mı?',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                    color: Color(0xFF667eea),
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

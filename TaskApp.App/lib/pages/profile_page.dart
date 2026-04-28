import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taskapp_app/widgets/shared_widgets.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showSnack('İsim ve e-posta alanları boş bırakılamaz.', isError: true);
      return;
    }

    if (password.isNotEmpty && password != confirmPassword) {
      _showSnack('Şifreler uyuşmuyor!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
      };

      if (password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('https://localhost:7062/api/User/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showSnack('Profil başarıyla güncellendi! 🎉');
        // Clear password fields after success
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        var errorMsg = 'Güncelleme başarısız oldu.';
        try {
          errorMsg = jsonDecode(response.body)['message'] ?? errorMsg;
        } catch (_) {}
        _showSnack(errorMsg, isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Bağlantı hatası: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: ValueListenableBuilder(
                      valueListenable: _nameController,
                      builder: (context, value, child) {
                        return Text(
                          value.text.isNotEmpty
                              ? value.text.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder(
                  valueListenable: _nameController,
                  builder: (context, value, child) {
                    return Text(
                      value.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _emailController,
                  builder: (context, value, child) {
                    return Text(
                      value.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Form Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StyledTextField(
                    controller: _nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  StyledTextField(
                    controller: _emailController,
                    label: 'E-posta',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Şifreyi Değiştir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StyledTextField(
                    controller: _passwordController,
                    label: 'Yeni Şifre',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StyledTextField(
                    controller: _confirmPasswordController,
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
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Değişiklikleri Kaydet',
                    onPressed: _isLoading ? null : _updateProfile,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

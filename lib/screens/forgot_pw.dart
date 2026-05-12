import 'package:flutter/material.dart';
import 'package:datn_20224010/services/auth_service.dart';

class ForgotPw extends StatefulWidget {
  const ForgotPw({super.key});

  @override
  State<StatefulWidget> createState() => _ForgotPwState();
}

class _ForgotPwState extends State<ForgotPw> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _sentSuccess = false;

  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _inputBg = Color(0xFFF2F4F3);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _errorRed = Color(0xFFE53935);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _sentSuccess = false;
    });

    final error = await AuthService().resetPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      setState(() => _sentSuccess = true);
    } else {
      setState(() => _errorText = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Quên mật khẩu',
                  style: TextStyle(
                    fontSize: 26,
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nhập email của bạn để nhận link đặt lại mật khẩu',
                  style: TextStyle(fontSize: 15, color: _textGrey),
                ),
                const SizedBox(height: 40),

                // ô nhập email
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 16, color: _textDark),
                    onChanged: (_) => setState(() {
                      _errorText = null;
                      _sentSuccess = false;
                    }),
                    decoration: const InputDecoration(
                      hintText: 'Nhập email',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: _textGrey,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // thông báo lỗi
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: _errorRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                              color: _errorRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // thông báo gửi thành công
                if (_sentSuccess) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline,
                            color: _primaryGreen, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Email đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư của bạn.',
                            style: TextStyle(
                              color: _primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // nút gửi
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Gửi yêu cầu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                // nút quay lại đăng nhập
                if (_sentSuccess) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
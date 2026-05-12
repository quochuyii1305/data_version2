import 'package:datn_20224010/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:datn_20224010/services/auth_service.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _CreateAccountState();
  }
}

class _CreateAccountState extends State<CreateAccount> {
  final _hotenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _repasswordController = TextEditingController();
  final _ngaySinhController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;
  String _gioiTinh = 'Nam';

  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _inputBg = Color(0xFFF2F4F3);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _errorRed = Color.fromARGB(255, 214, 72, 70);

  @override
  void dispose() {
    _hotenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repasswordController.dispose();
    _ngaySinhController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _ngaySinhController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  String? _validate() {
    if (_hotenController.text.trim().isEmpty) return 'Vui lòng nhập họ và tên';
    if (_emailController.text.trim().isEmpty) return 'Vui lòng nhập email';
    if (_ngaySinhController.text.isEmpty) return 'Vui lòng chọn ngày sinh';
    if (_passwordController.text.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (_passwordController.text.length < 6)
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    if (_passwordController.text != _repasswordController.text)
      return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }
    setState(() {
      _errorText = null;
      _isLoading = true;
    });
    final error = await AuthService().signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      hoTen: _hotenController.text.trim(),
      ngaySinh: _ngaySinhController.text,
      gioiTinh: _gioiTinh,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Đăng ký thành công -> Vào thẳng MainScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
        (route) => false,
      );
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'Đăng ký',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildInputField(
                controller: _hotenController,
                hintText: "Họ và tên",
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _emailController,
                hintText: "Email",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _passwordController,
                hintText: 'Mật khẩu',
                obscureText: _obscurePassword,
                suffixIcon: _buildEyeIcon(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _pickDate(),
                child: Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _inputBg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _ngaySinhController.text.isEmpty
                              ? 'Ngày sinh'
                              : _ngaySinhController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: _ngaySinhController.text.isEmpty
                                ? _textGrey
                                : _textDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gioiTinh,
                    items: ['Nam', 'Nữ', 'Khác']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _gioiTinh = value ?? 'Nam'),
                    style: const TextStyle(fontSize: 16, color: _textDark),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: _textGrey,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12),
              _buildInputField(
                controller: _repasswordController,
                hintText: 'Xác nhận lại mật khẩu',
                obscureText: _obscurePassword,
                suffixIcon: _buildEyeIcon(),
              ),
                 if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(_errorText!, style: const TextStyle(color: _errorRed, fontSize: 13)),
              ],

              SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    _isLoading ? null : _submit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Đăng ký',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bạn đã có tài khoản? ',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEyeIcon() {
    return GestureDetector(
      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _primaryGreen,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, color: _textDark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: _textGrey,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

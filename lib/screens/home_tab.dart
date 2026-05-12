import 'package:flutter/material.dart';
import 'package:datn_20224010/services/mqtt_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with SingleTickerProviderStateMixin {

  bool _isConnected  = false;
  bool _isConnecting = false;

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _lightGreen   = Color(0xFFE8F5EE);
  static const Color _textGrey     = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _isConnected = MqttService.instance.isConnected;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (_isConnected) {
      MqttService.instance.disconnect();
      setState(() => _isConnected = false);
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final success = await MqttService.instance.connect();

      if (mounted) {
        if (success) {
          setState(() {
            _isConnected  = true;
            _isConnecting = false;
          });
        } else {
          setState(() => _isConnecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kết nối thất bại — kiểm tra WiFi hoặc broker'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 32),
          _buildConnectionCard(),
          const SizedBox(height: 24),
          _buildConnectButton(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _lightGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/heart_logo.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.favorite,
              color: _primaryGreen,
              size: 54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // icon wifi với animation nhấp nháy
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _isConnecting ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected
                        ? const Color(0xFFE8F5EE)
                        : _isConnecting
                            ? const Color(0xFFFFF8E1)
                            : const Color(0xFFFFEBEE),
                  ),
                  child: Icon(
                    _isConnected
                        ? Icons.wifi_rounded
                        : _isConnecting
                            ? Icons.wifi_find_rounded
                            : Icons.wifi_off_rounded,
                    color: _isConnected
                        ? _primaryGreen
                        : _isConnecting
                            ? Colors.orange
                            : Colors.redAccent,
                    size: 26,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // chữ mô tả trạng thái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected
                      ? 'Đã kết nối'
                      : _isConnecting
                          ? 'Đang kết nối...'
                          : 'Chưa kết nối',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _isConnected
                        ? _primaryGreen
                        : _isConnecting
                            ? Colors.orange
                            : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isConnected
                      ? 'Thiết bị đang hoạt động'
                      : _isConnecting
                          ? 'Đang tìm thiết bị...'
                          : 'Bấm nút bên dưới để kết nối',
                  style: const TextStyle(fontSize: 13, color: _textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isConnecting ? null : _toggleConnection,
        icon: _isConnecting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                _isConnected
                    ? Icons.link_off_rounded
                    : Icons.link_rounded,
                size: 22,
              ),
        label: Text(
          _isConnecting
              ? 'Đang kết nối...'
              : _isConnected
                  ? 'Ngắt kết nối'
                  : 'Kết nối thiết bị',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isConnected ? Colors.redAccent : _primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
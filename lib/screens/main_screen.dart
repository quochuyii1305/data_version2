import 'package:flutter/material.dart';
import 'package:datn_20224010/screens/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datn_20224010/services/auth_service.dart';
import 'package:datn_20224010/services/user_service.dart';
import 'package:datn_20224010/screens/benh_nhan_tab.dart';
import 'package:datn_20224010/screens/home_tab.dart';
import 'package:datn_20224010/screens/do_tab.dart';


class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _hoTen = '';
  bool _isLoadingUser = true;
  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final user = await UserService().getUser(uid);
      if (user != null && mounted) {
        setState(() {
          _hoTen = user.hoTen;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _logOut() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc muốn đăng xuất'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SignIn()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: _primaryGreen, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Xin chào,",
                  style: TextStyle(
                    fontSize: 14,
                    color: _textGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),

                _isLoadingUser
                    ? Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      )
                    : Text(
                        _hoTen,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),

          IconButton(
            onPressed: _logOut,
            icon: Icon(Icons.logout, color: Colors.red),
          ),
          SizedBox(width: 8),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_2_outlined,
              color: _primaryGreen,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:  return HomeTab();
      case 1:  return  DoTab();
      case 2:  return const BenhNhanTab();
      default: return const BenhNhanTab();
    }
  }


  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSlected = _selectedIndex == index;
    // tap 'đo' có viền nổi bật
    final bool isMeasure = index == 1;
    // custom button
    return GestureDetector(
      onTap: () => setState(() {
        _selectedIndex = index;
      }),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSlected
              ? (isMeasure ? const Color(0xFF1E7D4F) : _lightGreen)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, 
            color: isSlected 
            ? (isMeasure ? Colors.white : _primaryGreen)
            : _textGrey,
            size: 26,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSlected 
                ? (isMeasure ? Colors.white : _primaryGreen)
                : _textGrey,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(){
    return Container(
       decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black,
          offset: Offset(0, 2),

        )]
       ),
       child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Trang chủ'),
              _buildNavItem(1, Icons.monitor_heart, 'Đo'),
              _buildNavItem(2, Icons.people_alt_outlined, 'Bệnh nhân'),
            ],
          ),
          ),
        ),
    );
  }
}

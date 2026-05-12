import 'package:datn_20224010/screens/create_account.dart';
import 'package:datn_20224010/screens/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _MyHomeState();
  }
}

class _MyHomeState extends State<MyHome> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideUpAnimation;

  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  static const Color _textGrey = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    // bo dieu khien
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    // hieu ung mo dan
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    // hieu ung truot len
    _slideUpAnimation = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // safearea de noi dung k bi che boi tai tho
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // logo + ten app
              FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideUpAnimation,
                  child: Column(
                    // logo
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen,
                              offset: const Offset(0, 10),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/heart_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      SizedBox(height: 50),

                      // ten app
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 5, 63, 8),
                            Color.fromARGB(255, 128, 8, 32),
                          ],
                          begin: AlignmentGeometry.topLeft,
                          end: AlignmentGeometry.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Heart Protect',
                          style: GoogleFonts.playfairDisplay(
                            textStyle: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(139, 128, 64, 44),
                              letterSpacing: 1,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10),
                      // tag
                      const Text(
                        'Theo dõi sức khỏe tim mạch\ncủa bạn mỗi ngày',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _textGrey,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2,),
              // button
              FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: _slideUpAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // dang nhap button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>SignIn()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14,),
                      
                      // dang ky button
                      SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_)=> CreateAccount()));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

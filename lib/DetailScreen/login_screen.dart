import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../SqfLitelocalstorage/UserDbHelper.dart';
import '../HomePage/HomePage.dart';
import 'dart:ui';
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  final String? apikey;
  const LoginScreen({Key? key, this.apikey}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Thử đăng nhập với Firebase trước
    final userCredential = await _authService.signInWithEmailAndPassword(email, password);

    if (userCredential != null) {
      // Lưu vào SQLite nếu chưa có
      final userDb = UserDbHelper();
      final user = await userDb.getUserByEmail(email);
      if (user == null) {
        await userDb.insertUser(email, password);
      }

      // Chuyển sang trang main
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MyHomePage(apikey: widget.apikey)),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final userCredential = await _authService.signInWithGoogle();

    if (userCredential != null) {
      // Lưu thông tin user vào SQLite
      final userDb = UserDbHelper();
      final email = userCredential.user?.email ?? '';
      final user = await userDb.getUserByEmail(email);
      if (user == null) {
        await userDb.insertUser(email, 'google_auth');
      }

      // Chuyển sang trang main
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MyHomePage(apikey: widget.apikey)),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF181818),
              Color(0xFF232526),
              Color(0xFF414345),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner với Logo
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner bo góc lớn và bóng đổ
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(48),
                        bottomRight: Radius.circular(48),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(48),
                        bottomRight: Radius.circular(48),
                      ),
                      child: Image.asset(
                        'assets/movie_banner.jpg',
                        width: double.infinity,
                        height: 400,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Overlay gradient mạnh hơn
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(48),
                        bottomRight: Radius.circular(48),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.75),
                          Colors.transparent,
                          Colors.black.withOpacity(0.25),
                        ],
                        stops: [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Hiệu ứng blur nhẹ ở dưới
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(48),
                        bottomRight: Radius.circular(48),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          height: 40,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                  // Logo avatar động như cũ
                  Positioned(
                    bottom: -54,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedLogoAvatar(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 70),
              // Tiêu đề và mô tả
              Text(
                'Welcome to MovieApp',
                style: TextStyle(
                  color: Colors.amber.shade400,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enjoy the world of movies at your fingertips',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 28),
              // Form đăng nhập
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                    ),

                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                    ),
                    SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: SignInButton(
                            Buttons.Google,
                            onPressed: _signInWithGoogle,
                            text: ' Login with Google',
                          ),
                        ),
                        SizedBox(width: 12),

                      ],
                    ),
                    SizedBox(height: 18),
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedLogoAvatar extends StatefulWidget {
  @override
  _AnimatedLogoAvatarState createState() => _AnimatedLogoAvatarState();
}

class _AnimatedLogoAvatarState extends State<AnimatedLogoAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: CircleAvatar(
        backgroundImage: AssetImage('assets/movie_logo.jpg'),
        radius: 54,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

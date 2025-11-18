import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'HomePage/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'DetailScreen/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase không truyền options (Android/iOS dùng file google-services.json/GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  
  SharedPreferences? sp;
  try {
    sp = await SharedPreferences.getInstance();
  } catch (e) {
    print("Error initializing SharedPreferences: $e");
  }
  String imagepath = sp?.getString('imagepath') ?? '';
  String? apikey;
  try {
    await dotenv.load(fileName: ".env");
    apikey = dotenv.env['apikey'];
  } catch (e) {
    print("Error loading .env file: $e");
  }
  runApp(MyApp(imagepath: imagepath, apikey: apikey));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom]);
}

class MyApp extends StatelessWidget {
  final String imagepath;
  final String? apikey;
  const MyApp({super.key, required this.imagepath, this.apikey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieApp',
      builder: (context, child) {
        return ForcedMobileView(child: child!);
      },
      home: AuthWrapper(apikey: apikey),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final String? apikey;
  const AuthWrapper({super.key, this.apikey});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.amber.shade400,
              ),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in
          return MyHomePage(apikey: apikey);
        } else {
          // User is not signed in
          return LoginScreen(apikey: apikey);
        }
      },
    );
  }
}

class ForcedMobileView extends StatelessWidget {
  final Widget child;

  const ForcedMobileView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const double mobileWidth = 500;
    const double mobileHeight = 1150;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (screenWidth > mobileWidth || screenHeight > mobileHeight) {
      return Column(
        children: [
          const Text(
            'Zoom out browser to see full screen',
            style: TextStyle(fontSize: 30, color: Colors.black),
          ),
          const SizedBox(height: 10),
          const Text(
            'all features might not work in web',
            style: TextStyle(fontSize: 30, color: Colors.black),
          ),
          const SizedBox(height: 60),
          Center(
            child: Container(
              width: mobileWidth,
              height: mobileHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.5), blurRadius: 10),
                ],
              ),
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(mobileWidth, mobileHeight),
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  padding: MediaQuery.of(context).padding,
                  viewInsets: MediaQuery.of(context).viewInsets,
                ),
                child: child,
              ),
            ),
          ),
        ],
      );
    }
    return child;
  }
}

class IntermediateScreen extends StatefulWidget {
  final String? apikey;
  const IntermediateScreen({super.key, this.apikey});

  @override
  State<IntermediateScreen> createState() => _IntermediateScreenState();
}

class _IntermediateScreenState extends State<IntermediateScreen> {
  @override
  Widget build(BuildContext context) {
    print("Building IntermediateScreen");
    return AnimatedSplashScreen(
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      duration: 2000,
      nextScreen: MyHomePage(apikey: widget.apikey),
      splash: Container(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/icon.png'),
                        fit: BoxFit.contain),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  child: const Text(
                    'By Vinh Dragon:The King Who Killed Bardust',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      splashTransition: SplashTransition.fadeTransition,
      splashIconSize: 200,
      centered: true,
    );
  }
}

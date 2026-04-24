import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      AuthenticationRepository.instance.screenRedirect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          // TRUE CENTER (both vertically and horizontally)
          Center(
            child: Image.asset(
              'assets/logos/mdmpi-logo-animation.gif',
              width: 140,
              height: 140,
            ),
          ),

          // TEXT positioned LOWER, independent of center
          Positioned(
            bottom: 80, // adjust this value as needed
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Efficiency in Every Tap",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
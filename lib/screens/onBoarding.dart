import 'dart:async';
import 'package:classinsight/Widgets/PageTransitions.dart';
import 'package:classinsight/screens/LoginAs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Widgets/BaseScreen.dart';
import 'package:classinsight/utils/fontStyles.dart';

class OnBoarding extends StatefulWidget {
  @override
  _OnBoardingState createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _timer = Timer(const Duration(seconds: 2), () {
      _animationController.forward();
      // Navigate to role selection screen after animation
      Timer(const Duration(milliseconds: 500), () {
        Go.to(() => LoginAs());
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(),
      body: BaseScreen(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 1),
                end: Offset(0, -0.2),
              ).animate(_animation),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "Class Insight",
                      style: Font_Styles.largeHeadingBold(context),
                    ),
                    Text(
                      "A School Management System",
                      style: Font_Styles.labelHeadingLight(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

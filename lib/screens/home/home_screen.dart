import 'package:app_artwork/app_artwork.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'Home Screen';
  static const path = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double w = screenWidth;
    if (screenHeight < screenWidth) {
      w = screenHeight;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      body: Center(
          child: SizedBox(
        width: w * 0.618,
        height: w * 0.618,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: Center(
            child: Column(
              children: [
                LaddingPageLottie(width: w * 0.382, height: w * 0.382),
                Text(
                  context.l10n.welcomeHome,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

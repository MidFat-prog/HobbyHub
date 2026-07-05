import 'package:flutter/material.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget? child;
  
  const BackgroundContainer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFc5aae6),
            Color(0xFFabc2e6),
          ],
        ),
      ),
      child: child,
    );
  }
}

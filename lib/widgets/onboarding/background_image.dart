import 'package:flutter/material.dart'; 

class BackgroundImage extends StatelessWidget {
  final String imagePath; 

  const BackgroundImage({
    super.key, 
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: Image.asset(
          imagePath,
          key: ValueKey<String>(imagePath), 
          fit: BoxFit.cover,
          width: double.infinity,  
          height: double.infinity, 
        ),
      ),
    );
  }
}
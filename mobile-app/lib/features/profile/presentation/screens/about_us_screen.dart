import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Learnova helps learners build skills with guided modules, assessments, and progress tracking. '
          'This is a placeholder About Us page and can be replaced with your final company mission and details.',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

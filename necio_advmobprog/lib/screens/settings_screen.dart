import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

// ENHANCEMENT 3: Settings page to move the dark/light mode switch.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENHANCEMENT 3: Dark/light mode switch on the settings page.
              SwitchListTile(
                title: CustomText(
                  text: 'Dark Mode',
                  fontSize: 16.sp,
                ),
                subtitle: CustomText(
                  text: themeModel.isDark
                      ? 'Dark theme is enabled'
                      : 'Light theme is enabled',
                  fontSize: 13.sp,
                ),
                value: themeModel.isDark,
                onChanged: (_) => themeModel.toggleTheme(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

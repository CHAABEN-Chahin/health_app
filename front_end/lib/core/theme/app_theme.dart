import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryDark,
      primaryColor: AppColors.pinkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.pinkPrimary,
        secondary: AppColors.purplePrimary,
        surface: AppColors.secondaryDark,
        background: AppColors.primaryDark,
        error: AppColors.emergencyRed,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: AppTextStyles.header3,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.secondaryDark,
        elevation: 8,
        shadowColor: AppColors.pinkPrimary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withAlpha(24),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withAlpha(24),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.pinkPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.emergencyRed,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.mediumGray,
        ),
        labelStyle: AppTextStyles.bodyMedium,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pinkPrimary,
          foregroundColor: AppColors.white,
          elevation: 4,
          shadowColor: AppColors.pinkPrimary.withAlpha(105),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pinkPrimary,
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.white,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.white.withAlpha(24),
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondaryDark,
        selectedItemColor: AppColors.pinkPrimary,
        unselectedItemColor: AppColors.mediumGray,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.secondaryDark,
        elevation: 16,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.secondaryDark,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: AppTextStyles.header3,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.white;
          }
          return AppColors.mediumGray;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.pinkPrimary;
          }
          return AppColors.darkGray;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.pinkPrimary,
        inactiveTrackColor: AppColors.darkGray,
        thumbColor: AppColors.white,
        overlayColor: AppColors.pinkPrimary.withAlpha(48),
        valueIndicatorColor: AppColors.pinkPrimary,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.pinkPrimary,
        linearTrackColor: AppColors.darkGray,
        circularTrackColor: AppColors.darkGray,
      ),
    );
  }
}

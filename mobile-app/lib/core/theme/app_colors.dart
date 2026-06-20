import 'package:flutter/material.dart';

class ColorManager {
  // --- Constants (Mainly used in Dark Mode or shared) ---
  static const Color primary = Color(0xFF72F7D7);
  static const Color secondary = Color(0xFF041C32);
  static const Color background = Color(0xFF041C32);
  static const Color backgroundLight = Color(0xFFF6FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFF03478E);
  static const Color backgroundSecondaryLight = Color(0xFFE9F4FF);
  static const Color darkGrey = Color(0xFF525252);
  static const Color lightGrey = Color(0xFF9E9E9E);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color error = Color(0xFFE61F34);
  static const Color warning = Color(0xFFF4C542);
  static const Color transparent = Color(0x00000000);

  static const Color borderWeak = Color(0x1AFFFFFF);
  static const Color borderSoft = Color(0x3DFFFFFF);
  static const Color overlaySoft = Color(0x0DFFFFFF);
  static const Color overlayMedium = Color(0x1FFFFFFF);
  static const Color overlayStrong = Color(0x99FFFFFF);

  // Home/content feature-specific tokens
  static const Color progressTrack = Color(0xFF003366);
  static const Color buttonDark = Color(0xFF001A33);
  static const Color accentBlue = Color(0xFF0B4E95);
  static const Color infoMuted = Color(0xFF8493A5);
  static const Color contentBackground = Color(0xFF00172E);
  static const Color contentBackgroundAlt = Color(0xFF01172E);
  static const Color videoGradientStart = Color(0xFF09417A);
  static const Color videoGradientEnd = Color(0xFF042444);
  static const Color mutedSlate = Color(0xFF5F7085);
  static const Color tagBlue = Color(0xFF0C355F);
  static const Color surfaceTint = Color(0xFFEFF4FA);
  static const Color surfaceBorder = Color(0xFFCCD7E5);
  static const Color contentShadow = Color(0x6601172E);
  static const Color accentCyan = Color(0xFF15CEE5);
  static const Color subtitlesActive = Color(0xFF62F9E9);
  static const Color sheetSurface = Color(0xFFE9E9E9);
  static const Color sheetText = Color(0xFF1D1D1D);
  static const Color sheetTextAlt = Color(0xFF252525);
  static const Color contentBottomGlowStart = Color(0xFF0D3D86);
  static const Color contentBottomGlowEnd = Color(0xFF08428F);
  static const Color overlayScrim = Color(0x40121212);
  static const Color bookmarkGradientStart = Color(0xFF6CEDEB);
  static const Color bookmarkGradientEnd = Color(0xFF0057A6);
  static const Color dangerBright = Color(0xFFFF4444);
  static const Color accentMint = Color(0xFF3DA9A5);
  static const Color uiBlueDeep = Color(0xFF0A3F73);
  static const Color uiBlue600 = Color(0xFF0E57A7);
  static const Color uiBlueBorder = Color(0xFF0E5FAF);
  static const Color uiBlueBorderStrong = Color(0xFF0F66BE);
  static const Color uiBlue500 = Color(0xFF47A7FF);
  static const Color uiBlue450 = Color(0xFF31B8E3);
  static const Color uiBlue400 = Color(0xFF2C6CB1);
  static const Color uiBlue300 = Color(0xFF72A5F7);
  static const Color uiBlue700 = Color(0xFF3D6BAE);
  static const Color uiBlueGreen = Color(0xFF48A999);
  static const Color uiBlueTone = Color(0xFF0C5B8A);
  static const Color uiBlueToneDark = Color(0xFF0C4B93);
  static const Color uiBlueToneDarker = Color(0xFF0D4A8D);
  static const Color uiBlueToneStrong = Color(0xFF0D4E9A);
  static const Color uiPanelDark = Color(0xFF10151C);
  static const Color uiInkDark = Color(0xFF121212);
  static const Color uiInkDeep = Color(0xFF0C1C2B);
  static const Color softMint = Color(0xFF6CF3D7);
  static const Color softBlueTint = Color(0xFFB8D5E5);
  static const Color softBlueSurface = Color(0xFFD9E9F2);
  static const Color badgeBorder = Color(0xFF3A73BB);
  static const Color glowMintStrong = Color(0xCC8FFFE4);
  static const Color glowMintSoft = Color(0x5C83EFD9);
  static const Color overlayBlackSoft = Color(0x12000000);
  static const Color overlayBlackMild = Color(0x14000000);
  static const Color panelBlueTint = Color(0x334A9EFF);
  static const Color panelBlueBorder = Color(0x4C8AB8FF);
  static const Color dividerSoft = Color(0x33FFFFFF);

  // Text Colors
  static const Color textPrimary = ColorManager.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x61FFFFFF);
  static const Color textOnLight = Color(0xFF0F172A);

  // Light mode gradient background
  static const Color lightGradientStart = Color(0xFFFAFBFD);
  static const Color lightGradientEnd = Color(0xFFC7D6E6);

  // --- Theme Resolver Logic ---

  /// Helper to resolve colors based on theme.
  /// 
  /// Usually, [primary] (Mint) is for dark and [#03478E] for light.
  static Color getPrimary(bool isDark) => isDark ? primary : const Color(0xFF03478E);

  static Color getSecondary(bool isDark) => secondary;

  static Color getBackground(bool isDark) => isDark ? background : backgroundLight;

  static Color getBackgroundSecondary(bool isDark) => isDark ? backgroundSecondary : backgroundSecondaryLight;

  static Color getTextPrimary(bool isDark) => isDark ? white : textOnLight;

  static Color getTextSecondary(bool isDark) => isDark ? textSecondary : darkGrey;

  static Color getButtonBackground(bool isDark) => isDark ? white : const Color(0xFF01172E);

  static Color getButtonForeground(bool isDark) => isDark ? secondary : white;
  
  static Color getBorderWeak(bool isDark) => isDark ? borderWeak : const Color(0xFFE2E8F0);
  
  static Color getBorderSoft(bool isDark) => isDark ? borderSoft : const Color(0xFFCBD5E1);
}

import 'package:ardrive_ui/ardrive_ui.dart';
import 'package:flutter/material.dart';

part 'colors.dart';
part 'constants.dart';

class ThemeDetector {
  ArDriveThemes getOSDefaultTheme() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    if (brightness == Brightness.dark) {
      return ArDriveThemes.dark;
    } else {
      return ArDriveThemes.light;
    }
  }
}

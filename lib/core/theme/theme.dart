import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
  );

  static const VisualDensity _visualDensity = VisualDensity.compact;

  static const Radius _defaultRadius = Radius.circular(10);

  static const AppBarThemeData _appBarTheme = AppBarThemeData(
    toolbarHeight: 34,
  );

  static final NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
        height: 64,
        indicatorColor: Colors.transparent,
        backgroundColor: _colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: _colorScheme.primary,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            );
          }
          return TextStyle(
            color: _colorScheme.onSecondaryContainer,
            overflow: TextOverflow.ellipsis,
          );
        }),
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _colorScheme,
      visualDensity: _visualDensity,
      appBarTheme: _appBarTheme,
      navigationBarTheme: _navigationBarTheme,
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: _defaultRadius),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _colorScheme,
      visualDensity: _visualDensity,
      appBarTheme: _appBarTheme,
      navigationBarTheme: _navigationBarTheme,
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: _defaultRadius),
        ),
      ),
    );
  }
}

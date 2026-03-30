import 'package:flutter/material.dart';


// TEMA LIGHT
ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFE9ECEF), //negro y blanco
    secondary: Color(0xFF1A1A1F), //gris y negro
    surface: Color(0xFF000000), // blanco y negro
    onPrimary: Color(0xFF1A1A1F)
  ),
  
 
);

// // TEMA DARK
// ThemeData darkTheme = ThemeData(
//   scaffoldBackgroundColor: const Color(0xFFFFFFFF),
//   colorScheme: const ColorScheme.light(
//      primary: Color(0xFFE9ECEF), //negro y blanco

//     secondary: Color(0xFF1A1A1F), //gris y negro
//     surface: Color(0xFF000000), // blanco y negro
//   ),
// );



ThemeData darkTheme = ThemeData(
  scaffoldBackgroundColor: Color(0xFF0D0D0F),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1A1A1F), //negro y blanco
    secondary: Color(0xFFE9ECEF), //gris y negro
    surface: Color(0xFFFFFFFF), // blanco y negro
    onPrimary: Color(0xFF1A1A1F)
  ),
);
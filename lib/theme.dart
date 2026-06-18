import 'package:flutter/material.dart';

// Identidad Fuerza de Ventas: azul Pichincha + blanco (diferenciado de app cliente).
const Color kPrimaryYellow = Color(0xFFFFD200); // acento opcional
const Color kPrimaryBlue = Color(0xFF004B8D);
const Color kBrandWhite = Colors.white;
const Color kAccentYellow = Color(0xFFFFE066);
const Color kBackground = Color(0xFFF7F9FB);
const Color kCardShadow = Color(0x1A000000);

// Estados de solicitudes
const Color statusSent = Color(0xFF1976D2); // azul claro
const Color statusCommittee = Color(0xFFFFA000); // ámbar / comité
const Color statusApproved = Color(0xFF2E7D32); // verde aprobado
const Color statusDisbursed = Color(0xFF6A1B9A); // morado para desembolso (opcional)

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: kPrimaryBlue,
    onPrimary: Colors.white,
    secondary: kBrandWhite,
    onSecondary: kPrimaryBlue,
    error: Colors.red.shade700,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: kBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kBrandWhite,
    foregroundColor: kPrimaryBlue,
    elevation: 6,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: kPrimaryBlue),
      foregroundColor: kPrimaryBlue,
    ),
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 4,
    shadowColor: kCardShadow,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kPrimaryBlue),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
  ),
);

// Helper para obtener color de estado por clave
Color applicationStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'enviado':
      return statusSent;
    case 'comité':
    case 'comite':
      return statusCommittee;
    case 'aprobado':
      return statusApproved;
    case 'desembolsado':
      return statusDisbursed;
    default:
      return Colors.grey;
  }
}

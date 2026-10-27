import 'package:flutter/material.dart';
import 'escaner.dart';

// -----------------------------------------------------------------------------
// PUNTO DE ENTRADA DE LA APLICACIÓN
// -----------------------------------------------------------------------------
void main() {
  // runApp enciende la app y le entrega el widget principal (InventarioApp)
  runApp(const InventarioApp());
}

// Configuración global de la App (Tema, Títulos, Colores)
class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Motoline',
      debugShowCheckedModeBanner: false, // Quita la etiqueta roja de "DEBUG" en la esquina
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F), // Rojo Motero / Mecánico principal
          brightness: Brightness.light,
        ),
      ),
      home: const PantallaEscanerOffline(), // Carga correctamente la pantalla del escáner
    );
  }
}

// -----------------------------------------------------------------------------
// ENTIDAD / MODELO DE DATOS (El molde de cada repuesto)
// -----------------------------------------------------------------------------
class Repuesto {
  final String id;
  final String codigo;
  final String categoria;
  final String nombre;
  double price; // Manteniendo compatibilidad
  int stock;
  final List<String> marcasCompatibles;

  Repuesto({
    required this.id,
    required this.codigo,
    required this.categoria,
    required this.nombre,
    required double precio,
    required this.stock,
    required this.marcasCompatibles,
  }) : price = precio;
}
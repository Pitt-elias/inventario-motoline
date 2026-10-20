import 'package:flutter/material.dart';

void main () {
    runApp(const InventarioApp())
}
class InventarioApp extends StatelessWidget{
    const InventarioApp ({super.key})

    @override
    Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Motoline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F), // Rojo Motero / Mecánico
          brightness: Brightness.light,
          ),
        ),
      home: const MainInventoryScreen(),
        );
      }
    } 

// -----------------------------------------------------------------------------
// ENTIDAD / MODELO DE DATOS
// -----------------------------------------------------------------------------


class Repuesto {
  final String id;
  final String codigo;
  final String categoria;
  final String nombre;
  double precio;
  int stock;
  final List<String> marcasCompatibles;

  Repuesto ({
    required this.id,
    required this.codigo,
    required this.categoria,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.marcasCompatibles,
  });
}
}
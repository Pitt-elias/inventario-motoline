import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// PUNTO DE ENTRADA DE LA APLICACIÓN
// -----------------------------------------------------------------------------
void main () {
    // runApp enciende la app y le entrega el widget principal (InventarioApp)
    runApp(const InventarioApp());
}

// Configuración global de la App (Tema, Títulos, Colores)
class InventarioApp extends StatelessWidget{
    const InventarioApp ({super.key});

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
        home: const PantallaPrincipalInventario(), // La pantalla que se muestra al abrir la app
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
  double precio;               // No es 'final' porque el precio puede cambiar
  int stock;                   // No es 'final' porque el stock sube o baja al vender/recibir
  final List<String> marcasCompatibles;

  // Constructor requerido para instanciar objetos de tipo Repuesto
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
  
// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL CON NAVEGACIÓN DUAL (Controlador de Estado)
// -----------------------------------------------------------------------------
class PantallaPrincipalInventario extends StatefulWidget{
    const PantallaPrincipalInventario ({super.key});

    @override
    State<PantallaPrincipalInventario> createState() => _PantallaPrincipalInventario();
}

class _PantallaPrincipalInventario extends State<PantallaPrincipalInventario> {
    int _SelectedIndex = 0; // Controla qué pestaña está activa (0 para Almacén, 1 para Catálogo)

    // Base de datos temporal en la memoria RAM (simulando el Excel del proveedor)
    final List<Repuesto> _inventario = [
      Repuesto(
        id: '1',
        codigo: 'PAS-YAM-001',
        nombre: 'Pastillas de Freno Cerámicas Delanteras',
        categoria: 'Frenos',
        precio: 45000,
        stock: 12,
        marcasCompatibles: ['Yamaha', 'FZ 2.0'],
      ),
      Repuesto(
        id: '2',
        codigo: 'ACE-MOT-10W40',
        nombre: 'Kit de Arrastre Relación 428-132T',
        categoria: 'Transmisión',
        precio: 135000,
        stock: 5,
        marcasCompatibles: ['Honda', 'XR 150', 'CB 125F'],
      ),
      Repuesto(
        id: '3',
        codigo: 'ACE-MOT-10W40',
        nombre: 'Aceite Motul 7100 10W40 Sintético',
        categoria: 'Lubricantes',
        precio: 68000,
        stock: 24,
        marcasCompatibles: ['Universal / Multimarca'],
      ),
      Repuesto(
        id: '1',
        codigo: 'BAN-TRA-SUZ-05',
        nombre: 'Bandas de Freno Traseras HD',
        categoria: 'Frenos',
        precio: 28000,
        stock: 3,
        marcasCompatibles: ['Suzuki', 'GN 125', 'AX 100'],
      ),
    ];

    @override
    Widget build(BuildContext context) {
      // Scaffold construye la estructura visual base de la pantalla (AppBar, Cuerpo, etc.)
      return Scaffold(
        appBar: AppBar(title: const Text('Motoline - Módulo Repuestos')),
        body: Center(child: Text('Aquí irá el contenido de la pestaña $_SelectedIndex')),
      );
    }
}
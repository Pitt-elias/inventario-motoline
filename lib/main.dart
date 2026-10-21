import 'package:flutter/material.dart';

void main () {
    runApp(const InventarioApp());
}
class InventarioApp extends StatelessWidget{
    const InventarioApp ({super.key});

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
      home: const PantallaPrincipalInventario(),
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
  
// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL CON NAVEGACIÓN DUAL
// -----------------------------------------------------------------------------

  class PantallaPrincipalInventario extends StatefulWidget{
    const PantallaPrincipalInventario ({super.key});

    @override
    State<PantallaPrincipalInventario> createState() => _PantallaPrincipalInventario();
  }

  class _PantallaPrincipalInventario extends State<PantallaPrincipalInventario> {
    int _SelectedIndex = 0;

    //Base de datos temporal en la memoria (simulando el excel)
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
      return Scaffold(
        appBar: AppBar(title: const Text('Motoline - Módulo Repuestos')),
        body: Center(child: Text('Aquí irá el contenido de la pestaña $_SelectedIndex')),
      );
    }

    @override
    
}
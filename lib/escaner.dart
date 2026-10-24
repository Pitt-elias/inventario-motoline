import 'package:flutter/material.dart';                  // Biblioteca visual de Flutter: componentes gráficos para armar la interfaz (botones, Scaffold, etc.)
import 'package:hive_flutter/hive_flutter.dart';          // Hive: base de datos local NoSQL y ultraligera para guardar datos en la memoria del celular (Offline-First)
import 'package:excel/excel.dart';                        // Herramienta para crear y manipular archivos Excel (.xlsx) en Dart/Flutter (el "Pandas" de Flutter)
import 'package:path_provider/path_provider.dart';        // Paquete auxiliar para obtener las rutas carpetas del sistema operativo donde se pueden guardar archivos
import 'dart:io';                                         // Biblioteca nativa de Dart para interactuar con el SO (crear archivos, leer bytes físicos)

// -----------------------------------------------------------------------------
// PANTALLA DE ESCÁNER Y REGISTRO OFFLINE
// -----------------------------------------------------------------------------
class PantallaEscanerOffline extends StatefulWidget {
  const PantallaEscanerOffline({super.key});                                 // super.key le pasa la llave única de identificación a la clase madre StatefulWidget

  @override
  State<PantallaEscanerOffline> createState() => _PantallaEscanerOfflineState(); // Método obligatorio que vincula la estructura visual con la clase de estado y lógica
}
git add .
git commit -m "feat: agrego modulo offline-first con hive y generacion de excel local"
git push
class _PantallaEscanerOfflineState extends State<PantallaEscanerOffline> {
  bool _estaGuardando = false;                                                // Variable de control (bandera): si es true, deshabilita el botón para evitar guardados duplicados

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Facturas (Offline-First)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.wifi_off, size: 48, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      'Modo sin conexión activo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Toma la foto de la factura del proveedor. Los datos se guardarán localmente en el celular y podrás generar tu Excel cuando desees.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),                                                   // Spacer: Espaciador flexible que consume el espacio vacío sobrante para empujar/centrar los botones
            
            // Botón principal para simular o capturar el escaneo de la factura
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _estaGuardando ? null : () => _simularCapturaFactura(context), // Si _estaGuardando es true, desactiva el botón (null)
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Tomar Foto / Escanear Factura',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón para exportar los datos guardados a un archivo Excel local
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _generarArchivoExcelLocal(context),
              icon: const Icon(Icons.table_chart, color: Colors.green),
              label: const Text(
                'Generar y Descargar Excel Local',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LÓGICA 1: Guardar localmente el repuesto escaneado (Simulación de IA + Hive)
  // ---------------------------------------------------------------------------
  Future<void> _simularCapturaFactura(BuildContext context) async {
    setState(() {                                                             // setState: Notifica a Flutter que la variable cambió (_estaGuardando = true) y redibuja la interfaz
      _estaGuardando = true;
    });

    try {
      // Abrimos la "caja" de Hive (tabla) donde guardamos los registros localmente en el celular
      var cajaRepuestos = await Hive.openBox('facturas_locales');

      // Simulamos el diccionario con los datos limpios que extraeríamos de la factura mediante la IA
      var repuestoEscaneado = {
        'nombre_estandar': 'Centro de clutch',
        'descripcion_original': 'Campana con discos de clutch',
        'cantidad': 3,
        'precio_unitario': 45000,
        'fecha': DateTime.now().toString(),
      };

      // Guardamos el repuesto directamente en la memoria interna del celular (Storage local)
      await cajaRepuestos.add(repuestoEscaneado);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(                                                     // SnackBar: Notificación flotante emergente en la parte inferior de la pantalla
            content: Text('¡Factura escaneada y guardada localmente con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar localmente: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _estaGuardando = false;                                              // Reestablecemos la bandera en false al terminar para volver a habilitar el botón
      });
    }
  }

  // ---------------------------------------------------------------------------
  // LÓGICA 2: Crear el archivo Excel (.xlsx) directamente en el dispositivo
  // ---------------------------------------------------------------------------
  Future<void> _generarArchivoExcelLocal(BuildContext context) async {        // Future: Representa una tarea asíncrona que responderá a futuro sin congelar la pantalla
    try {
      var cajaRepuestos = await Hive.openBox('facturas_locales');
      
      if (cajaRepuestos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay datos guardados localmente para exportar.')),
        );
        return;
      }

      // Creamos un libro de Excel en memoria usando la librería 'excel'
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Inventario_Local'];
      excel.delete('Sheet1'); // Borramos la hoja vacía creada por defecto

      // Agregamos la fila de encabezados
      sheetObject.appendRow([                                                 // appendRow: Agrega una lista de celdas a la última fila disponible del Excel
        TextCellValue('Nombre Estándar'),
        TextCellValue('Descripción Original'),
        TextCellValue('Cantidad'),
        TextCellValue('Precio Unitario'),
        TextCellValue('Fecha Registro')
      ]);

      // Recorremos los registros guardados en Hive y los escribimos como filas del Excel
      for (var key in cajaRepuestos.keys) {
        var item = cajaRepuestos.get(key);
        sheetObject.appendRow([
          TextCellValue(item['nombre_estandar'].toString()),
          TextCellValue(item['descripcion_original'].toString()),
          IntCellValue(item['cantidad']),
          DoubleCellValue(item['precio_unitario'].toDouble()),
          TextCellValue(item['fecha'].toString()),
        ]);
      }

      // Obtenemos la ruta de documentos interna del celular usando path_provider
      Directory? directorio = await getApplicationDocumentsDirectory();       // Directory: Objeto que gestiona la ruta de la carpeta física en el sistema operativo
      String rutaArchivo = '${directorio.path}/inventario_motoline_offline.xlsx';

      // Guardamos físicamente el archivo .xlsx escribiendo sus bytes en el disco
      File(rutaArchivo)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Excel generado con éxito en el dispositivo!\nRuta: $rutaArchivo'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
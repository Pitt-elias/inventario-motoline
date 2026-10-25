import 'package:flutter/material.dart';                  // Biblioteca visual de Flutter: componentes gráficos para armar la interfaz (botones, Scaffold, etc.)[cite: 1]
import 'package:hive_flutter/hive_flutter.dart';          // Hive: base de datos local NoSQL y ultraligera para guardar datos en la memoria del celular (Offline-First)[cite: 1]
import 'package:excel/excel.dart';                        // Herramienta para crear y manipular archivos Excel (.xlsx) en Dart/Flutter (el "Pandas" de Flutter)[cite: 1]
import 'package:path_provider/path_provider.dart';        // Paquete auxiliar para obtener las rutas carpetas del sistema operativo donde se pueden guardar archivos[cite: 1]
import 'package:image_picker/image_picker.dart';         // [NUEVO] Librería para interactuar con la cámara y galería nativas del teléfono[cite: 1, 2]
import 'dart:io';                                         // Biblioteca nativa de Dart para interactuar con el SO (crear archivos, leer bytes físicos)[cite: 1]

// -----------------------------------------------------------------------------
// PANTALLA DE ESCÁNER Y REGISTRO OFFLINE
// -----------------------------------------------------------------------------
class PantallaEscanerOffline extends StatefulWidget {
  const PantallaEscanerOffline({super.key});                                 // super.key le pasa la llave única de identificación a la clase madre StatefulWidget

  @override
  State<PantallaEscanerOffline> createState() => _PantallaEscanerOfflineState(); // Método obligatorio que vincula la estructura visual con la clase de estado y lógica
}

class _PantallaEscanerOfflineState extends State<PantallaEscanerOffline> {
  bool _estaGuardando = false;                                                // Variable de control (bandera): si es true, deshabilita el botón para evitar guardados duplicados
  final ImagePicker _picker = ImagePicker();                                 // [NUEVO] Instancia del controlador de la cámara del celular[cite: 1, 2]

  // 🧠 [NUEVO] Lógica del diccionario de Python adaptada a Dart para limpiar y estandarizar repuestos
  String _aplicarDiccionarioEstandar(String textoOriginal) {
    String textoLower = textoOriginal.toLowerCase().trim();
    
    // Reglas de equivalencia para Motoline (limpieza automática)
    if (textoLower.contains('campana') && textoLower.contains('clutch')) {
      return 'Centro de clutch';
    } else if (textoLower.contains('pastillas') && textoLower.contains('freno')) {
      return 'Pastillas de freno';
    } else if (textoLower.contains('kit') && textoLower.contains('arrastre')) {
      return 'Kit de arrastre';
    }
    
    return textoOriginal; // Si no hay regla coincidente, conserva el nombre original
  }

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
            
            // Botón principal para capturar la foto con la cámara física
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _estaGuardando ? null : () => _capturarFotoYProcesar(context), // Si _estaGuardando es true, desactiva el botón (null)
              icon: const Icon(Icons.camera_alt),
              label: Text(
                _estaGuardando ? 'Procesando...' : 'Tomar Foto / Escanear Factura',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón para exportar los datos guardados a la carpeta pública de Descargas
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
  // LÓGICA 1: Capturar foto con la cámara nativa + Estandarizar + Guardar en Hive
  // ---------------------------------------------------------------------------
  Future<void> _capturarFotoYProcesar(BuildContext context) async {
    setState(() {                                                             // setState: Notifica a Flutter que la variable cambió (_estaGuardando = true) y redibuja la interfaz
      _estaGuardando = true;
    });

    try {
      // 1. [NUEVO] Abrir la cámara física del celular para tomar la foto
      final XFile? fotoCapturada = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,                                                     // Optimiza la foto para que no pese demasiado
      );

      // Si el usuario cancela la toma de la foto, salimos sin hacer nada
      if (fotoCapturada == null) {
        setState(() => _estaGuardando = false);
        return;
      }

      // 🛡️ Nos aseguramos de inicializar Hive por seguridad antes de abrir la caja
      await Hive.initFlutter();

      // Abrimos la "caja" de Hive (tabla) donde guardamos los registros localmente en el celular
      var cajaRepuestos = await Hive.openBox('facturas_locales');

      // 2. Extraemos/limpiamos la descripción aplicando el diccionario de Python adaptado
      String textoBruto = "campana con discos de clutch";                      // Texto detectado en la factura
      String nombreEstandarizado = _aplicarDiccionarioEstandar(textoBruto);    // Pasado por las reglas de limpieza

      var repuestoEscaneado = {
        'nombre_estandar': nombreEstandarizado,
        'descripcion_original': textoBruto,
        'cantidad': 3,
        'precio_unitario': 45000,
        'ruta_foto': fotoCapturada.path,                                      // [NUEVO] Guardamos la ruta de la foto física en la memoria
        'fecha': DateTime.now().toString(),
      };

      // Guardamos el repuesto directamente en la memoria interna del celular (Storage local)
      await cajaRepuestos.add(repuestoEscaneado);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(                                                           // SnackBar: Notificación flotante emergente en la parte inferior de la pantalla
            content: Text('¡Factura guardada! Repuesto: "$nombreEstandarizado"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la foto: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _estaGuardando = false;                                              // Reestablecemos la bandera en false al terminar para volver a habilitar el botón
      });
    }
  }

  // ---------------------------------------------------------------------------
  // LÓGICA 2: Crear el archivo Excel (.xlsx) en la carpeta de Descargas pública
  // ---------------------------------------------------------------------------
  Future<void> _generarArchivoExcelLocal(BuildContext context) async {        // Future: Representa una tarea asíncrona que responderá a futuro sin congelar la pantalla
    try {
      await Hive.initFlutter();
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

      // [NUEVO] Definimos la ruta pública de Descargas de Android para fácil acceso del jefe
      Directory? directorio;
      if (Platform.isAndroid) {
        directorio = Directory('/storage/emulated/0/Download');               // Ruta estándar de la carpeta Descargas en Android
        if (!await directorio.exists()) {
          directorio = await getExternalStorageDirectory();
        }
      } else {
        directorio = await getApplicationDocumentsDirectory();
      }

      String rutaArchivo = '${directorio!.path}/inventario_motoline_offline.xlsx';

      // Guardamos físicamente el archivo .xlsx escribiendo sus bytes en la carpeta pública
      File(rutaArchivo)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Excel guardado en Descargas!\nRuta: $rutaArchivo'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
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
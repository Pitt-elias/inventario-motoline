import 'package:flutter/material.dart';             // Componentes visuales de Flutter
import 'package:image_picker/image_picker.dart';    // Manejo de la cámara y galería
import 'package:http/http.dart' as http;             // Cliente HTTP para enviar datos a Python
import 'dart:convert';                              // Decodificador JSON

// -----------------------------------------------------------------------------
// CONFIGURACIÓN DE CONEXIÓN CON EL BACKEND DE PYTHON
// -----------------------------------------------------------------------------
const String urlServidorPython = 'https://fictional-pancake-vp6945rg5p6c69v9-8000.app.github.dev/procesar-factura/';

class PantallaEscanerOffline extends StatefulWidget {
  const PantallaEscanerOffline({super.key});

  @override
  State<PantallaEscanerOffline> createState() => _PantallaEscanerOfflineState();
}

class _PantallaEscanerOfflineState extends State<PantallaEscanerOffline> {
  bool _estaEnviando = false;
  final ImagePicker _picker = ImagePicker();

  // ---------------------------------------------------------------------------
  // LÓGICA DE CAPTURA Y ENVÍO POR BYTES (Compatible con Web y Móvil)
  // ---------------------------------------------------------------------------
  Future<void> _capturarYEnviarFactura(ImageSource origen) async {
    setState(() {
      _estaEnviando = true;
    });

    try {
      // 1. Seleccionamos o tomamos la foto
      final XFile? fotoCapturada = await _picker.pickImage(
        source: origen,
        imageQuality: 85,
      );

      if (fotoCapturada == null) {
        setState(() => _estaEnviando = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo foto al servidor de procesamiento...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 2. Leemos la imagen como Bytes (Esto soluciona el error en Flutter Web y dispositivos móviles)
      var bytesImagen = await fotoCapturada.readAsBytes();
      var nombreArchivo = fotoCapturada.name;

      // 3. Preparamos la petición HTTP Multipart usando los bytes en memoria
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(urlServidorPython),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Nombre del campo que espera FastAPI en Python
          bytesImagen,
          filename: nombreArchivo.isNotEmpty ? nombreArchivo : 'factura.jpg',
        ),
      );

      // 4. Enviamos la petición al servidor de Python
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 5. Analizamos la respuesta
      if (response.statusCode == 200) {
        var jsonRespuesta = jsonDecode(response.body);
        String mensaje = jsonRespuesta['mensaje'] ?? 'Factura enviada con éxito.';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $mensaje'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Error del servidor (${response.statusCode}). Reintente.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error de conexión: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _estaEnviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motoline - Escáner de Facturas'),
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
                    Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Escáner Inteligente en la Nube',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tome la foto de la factura del proveedor. El servidor procesará los repuestos automáticamente y actualizará el inventario en Excel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Botón para tomar foto o cargar imagen
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _estaEnviando ? null : () => _capturarYEnviarFactura(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(
                _estaEnviando ? 'Enviando al servidor...' : 'Tomar Foto de Factura',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Botón para seleccionar de la galería
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _estaEnviando ? null : () => _capturarYEnviarFactura(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text(
                'Seleccionar de Galería',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
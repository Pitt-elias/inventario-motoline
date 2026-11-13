import 'package:flutter/material.dart';          // Componentes visuales y de diseño de Flutter.
import 'package:image_picker/image_picker.dart';    // Manejo de la cámara y galería para las facturas.
import 'package:http/http.dart' as http;            // Cliente HTTP para enviar las fotos a Python.
import 'dart:convert';                              // Traductor de formato JSON.
import 'package:shared_preferences/shared_preferences.dart'; // Para almacenar la URL de forma persistente en el celular.

// -----------------------------------------------------------------------------
// CONFIGURACIÓN DE CONEXIÓN DINÁMICA
// -----------------------------------------------------------------------------
String urlServidorDinamica = 'http://192.168.1.50:8000/procesar-factura/'; // URL por defecto o de respaldo.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motoline Escáner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PantallaEscanerOffline(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PantallaEscanerOffline extends StatefulWidget {
  const PantallaEscanerOffline({super.key});

  @override
  State<PantallaEscanerOffline> createState() => _PantallaEscanerOfflineState();  
}

class _PantallaEscanerOfflineState extends State<PantallaEscanerOffline> {
  bool _estaEnviando = false;   
  final ImagePicker _picker = ImagePicker(); 

  @override
  void initState() {
    super.initState();
    _cargarUrlGuardada(); // Al iniciar la app, recuperamos la IP guardada previamente en el celular.
  }

  // Carga la URL almacenada en la memoria local del dispositivo
  Future<void> _cargarUrlGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final urlGuardada = prefs.getString('url_servidor_motoline');
    if (urlGuardada != null && urlGuardada.isNotEmpty) {
      setState(() {
        urlServidorDinamica = urlGuardada;
      });
    }
  }

  // Lógica para capturar la foto y enviarla al servidor configurado
  Future<void> _capturarYEnviarFactura(ImageSource origen) async {
    setState(() {
      _estaEnviando = true;
    });

    try {
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
            content: Text('Subiendo foto al servidor del taller...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      var bytesImagen = await fotoCapturada.readAsBytes();
      var nombreArchivo = fotoCapturada.name;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(urlServidorDinamica),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytesImagen,
          filename: nombreArchivo.isNotEmpty ? nombreArchivo : 'factura.jpg',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

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
            content: Text('❌ Error de conexión con $urlServidorDinamica: $e'),
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

  // Diálogo emergente para ingresar la IP manualmente en lugar de usar el QR
  void _mostrarDialogoIpManual() {
    // Controlador para obtener el texto que escriba el usuario
    final TextEditingController controller = TextEditingController(text: urlServidorDinamica);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurar IP del Servidor'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'URL del Servidor',
              hintText: 'Ej: http://192.168.1.50:8000/procesar-factura/',
            ),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cierra el diálogo sin guardar
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevaUrl = controller.text.trim();
                if (nuevaUrl.isNotEmpty) {
                  setState(() {
                    urlServidorDinamica = nuevaUrl;
                  });

                  // Guardamos la nueva IP de forma permanente en el celular
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('url_servidor_motoline', nuevaUrl);

                  if (mounted) {
                    Navigator.pop(context); // Cierra el diálogo
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🔗 IP actualizada con éxito:\n$nuevaUrl'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motoline - Escáner de Facturas'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Botón en la barra superior para cambiar la IP manualmente
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: Colors.greenAccent),
            tooltip: 'Configurar IP Manual',
            onPressed: _mostrarDialogoIpManual,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Escáner Inteligente en Red Local',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tome la foto de la factura. El servidor procesará los repuestos automáticamente y actualizará el inventario en Excel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Conectado a:\n$urlServidorDinamica',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
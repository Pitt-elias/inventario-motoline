import 'package:flutter/material.dart';          // Componentes visuales y de diseño de Flutter.
import 'package:image_picker/image_picker.dart';    // Manejo del hardware para tomar fotos con la cámara o elegirlas de la galería.
import 'package:http/http.dart' as http;            // Cliente HTTP oficial para enviar las peticiones y archivos al servidor de Python.
import 'dart:convert';                              // Decodificador de JSON para interpretar las respuestas del servidor.
// import 'package:shared_preferences/shared_preferences.dart'; // (Opcional recomendado) Para guardar la URL del QR de forma permanente en el celular.

// -----------------------------------------------------------------------------
// CONFIGURACIÓN DE CONEXIÓN DINÁMICA
// -----------------------------------------------------------------------------
// Variable global o local que almacena la URL del servidor obtenida mediante el código QR.
// Si no se ha escaneado nada, podemos dejar una URL de respaldo por defecto.
String urlServidorDinamica = 'http://192.168.1.50:8000/procesar-factura/'; 


class PantallaEscanerOffline extends StatefulWidget {
  const PantallaEscanerOffline({super.key});

  @override
  State<PantallaEscanerOffline> createState() => _PantallaEscanerOfflineState();  
  // createState conecta nuestro StatefulWidget dinámico con su clase de estado _PantallaEscanerOfflineState, 
  // que es donde ocurren los cambios visuales y la lógica.
}

class _PantallaEscanerOfflineState extends State<PantallaEscanerOffline> {
  bool _estaEnviando = false;   // Variable booleana (true/false) para saber si la app está ocupada enviando una foto (bloquea botones para evitar doble clic).
  final ImagePicker _picker = ImagePicker(); // Instanciamos la clase ImagePicker para poder usar la cámara y galería del celular.

  // ---------------------------------------------------------------------------
  // LÓGICA DE CAPTURA Y ENVÍO POR BYTES (Compatible con Web y Móvil)
  // ---------------------------------------------------------------------------
  Future<void> _capturarYEnviarFactura(ImageSource origen) async {
    // Actualizamos el estado visual para reflejar que estamos enviando una foto.
    setState(() {
      _estaEnviando = true;
    });

    try {
      // 1. Abrimos la cámara o galería para seleccionar o tomar la foto de la factura.
      final XFile? fotoCapturada = await _picker.pickImage(
        source: origen,
        imageQuality: 85, // Comprimimos ligeramente la calidad (85%) para que viaje más rápido por la red Wi-Fi.
      );

      // Si el usuario cancela la toma de foto, detenemos el proceso y reactivamos los botones.
      if (fotoCapturada == null) {
        setState(() => _estaEnviando = false);
        return;
      }

      // Mostramos un aviso flotante (SnackBar) indicando que la subida ha comenzado.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo foto al servidor de procesamiento...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 2. Leemos la imagen cruda como una secuencia de Bytes en la memoria RAM (evita problemas de rutas en Android/iOS/Web).
      var bytesImagen = await fotoCapturada.readAsBytes();
      var nombreArchivo = fotoCapturada.name;

      // 3. Preparamos una petición HTTP tipo Multipart (necesaria cuando enviamos archivos pesados como fotos).
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(urlServidorDinamica), // Apuntamos a la URL dinámica configurada (la obtenida por el QR).
      );

      // Adjuntamos los bytes de la imagen dentro de la petición simulando un formulario web.
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Nombre exacto del campo que espera recibir FastAPI en Python (@app.post("/procesar-factura/"))
          bytesImagen,
          filename: nombreArchivo.isNotEmpty ? nombreArchivo : 'factura.jpg',
        ),
      );

      // 4. Enviamos la petición streamed al servidor de Python de forma asíncrona.
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 5. Analizamos el código de estado devuelto por el servidor (200 significa éxito total).
      if (response.statusCode == 200) {
        var jsonRespuesta = jsonDecode(response.body); // Traducimos la respuesta de texto JSON a un mapa de datos de Flutter.
        String mensaje = jsonRespuesta['mensaje'] ?? 'Factura enviada con éxito.';

        if (mounted) {
          // Mostramos una alerta verde de éxito en la pantalla del celular.
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
          // Si el servidor responde con un código de error (ej. 500), avisamos al usuario.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Error del servidor (${response.statusCode}). Reintente.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Capturamos cualquier error crítico de red (ej. si el celular perdió el Wi-Fi o el PC está apagado).
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
      // Bloque que se ejecuta siempre al final (haya éxito o error) para desbloquear la interfaz.
      if (mounted) {
        setState(() {
          _estaEnviando = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CONSTRUCCIÓN DE LA INTERFAZ VISUAL (UI)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motoline - Escáner de Facturas'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Botón extra en la barra superior para simular la opción de escanear el QR de configuración
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear QR de Servidor',
            onPressed: () {
              // Aquí implementarías la navegación a tu pantalla de lectura de QR
              // que actualiza la variable 'urlServidorDinamica'.
            },
          ),
        ],
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
                      'Escáner Inteligente en Red Local',
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

            // Botón principal para tomar foto con la cámara
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              // Si _estaEnviando es true, onPressed pasa a ser 'null' (desactivando el botón visualmente).
              onPressed: _estaEnviando ? null : () => _capturarYEnviarFactura(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(
                _estaEnviando ? 'Enviando al servidor...' : 'Tomar Foto de Factura',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Botón secundario para seleccionar imagen desde la galería del celular
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
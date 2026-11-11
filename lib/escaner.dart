          import 'package:flutter/material.dart';          // Componentes visuales y de diseño de Flutter.
          import 'package:image_picker/image_picker.dart';    // Manejo de la cámara y galería para las facturas.
          import 'package:http/http.dart' as http;            // Cliente HTTP para enviar las fotos a Python.
          import 'dart:convert';                              // Traductor de formato JSON.
          import 'package:mobile_scanner/mobile_scanner.dart'; // Librería para escanear el código QR del servidor.
          import 'package:shared_preferences/shared_preferences.dart'; // Para almacenar la URL de forma persistente en el celular.

          // -----------------------------------------------------------------------------
          // CONFIGURACIÓN DE CONEXIÓN DINÁMICA
          // -----------------------------------------------------------------------------
          String urlServidorDinamica = 'http://192.168.1.50:8000/procesar-factura/'; //para qué vamos a utilizar esta url? no se supone que deberíamos almacenar la IP desde el código QR?

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
              _cargarUrlGuardada(); 
            }

            Future<void> _cargarUrlGuardada() async {
              final prefs = await SharedPreferences.getInstance();
              final urlGuardada = prefs.getString('url_servidor_motoline');
              if (urlGuardada != null && urlGuardada.isNotEmpty) {
                setState(() {
                  urlServidorDinamica = urlGuardada;
                });
              }
            }

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

            void _abrirEscanerQR() async {
              final resultadoURL = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaVistaQR(),
                ),
              );

              if (resultadoURL != null && resultadoURL is String && resultadoURL.isNotEmpty) {
                setState(() {
                  urlServidorDinamica = resultadoURL;
                });

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('url_servidor_motoline', resultadoURL);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔗 Servidor sincronizado con éxito:\n$resultadoURL'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 4),
                    ),
                  );
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
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.greenAccent),
                      tooltip: 'Escanear QR de Servidor',
                      onPressed: _abrirEscanerQR,
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

          // -----------------------------------------------------------------------------
          // PANTALLA AUXILIAR DE ESCANEO DE CÓDIGO QR (Con depuración visual en pantalla)
          // -----------------------------------------------------------------------------
          class PantallaVistaQR extends StatefulWidget {
            const PantallaVistaQR({super.key});

            @override
            State<PantallaVistaQR> createState() => _PantallaVistaQRState();
          }

          class _PantallaVistaQRState extends State<PantallaVistaQR> {
            late MobileScannerController controller;
            bool _encontroQR = false;

            @override
            void initState() {
              super.initState();
              controller = MobileScannerController(
                detectionSpeed: DetectionSpeed.normal,
                facing: CameraFacing.back,
                torchEnabled: false,
              );
            }

            @override
            void dispose() {
              controller.dispose();
              super.dispose();
            }

            @override
            Widget build(BuildContext context) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Escanee el QR del Servidor'),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                body: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      // 🔍 AQUÍ CAPTURAMOS EL ERROR Y LO MOSTRAMOS EN TEXTO EN VEZ DEL '!'
                      errorBuilder: (context, error, child) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              '❌ Error técnico de cámara:\n\nCódigo: ${error.errorCode}\n\nMensaje: ${error.errorDetails?.message ?? error.toString()}',
                              style: const TextStyle(
                                color: Colors.redAccent, 
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                      onDetect: (capture) {
                        if (_encontroQR) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            _encontroQR = true;
                            final String codigoLeido = barcode.rawValue!;
                            controller.stop();
                            Navigator.pop(context, codigoLeido);
                            break;
                          }
                        }
                      },
                    ),
                    // Cuadro guía visual
                    Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.greenAccent, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Enfoque el código QR que aparece\nen la terminal de la computadora',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          backgroundColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }
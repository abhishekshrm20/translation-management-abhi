import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(_router);

  final server = await io.serve(handler, 'localhost', 8080);
  print('✅ Admin API running on http://${server.address.host}:${server.port}');
}

Response _router(Request request) {
  if (request.url.path == 'translations') {
    final sampleData = [
      {
        "id": "1",
        "key": "greeting",
        "translations": {"en": "Hello", "es": "Hola", "fr": "Bonjour"}
      },
      {
        "id": "2",
        "key": "farewell",
        "translations": {"en": "Goodbye", "es": "Adiós", "fr": "Au revoir"}
      }
    ];

    return Response.ok(jsonEncode(sampleData), headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*', // ✅ CORS fix
    });
  }

  return Response.notFound('Not found');
}

library pica;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:web/web.dart';

import 'log.dart' as logger;
import 'util.dart';
import 'window.dart';

extension type Pica._(JSObject _) implements JSObject {
  external JSPromise resize(
    ImageBitmap from,
    HTMLCanvasElement to,
  );
}

Future<Uint8List> resizeWithList({
  required Uint8List buffer,
  required int minWidth,
  required int minHeight,
  CompressFormat format = CompressFormat.jpeg,
  int quality = 88,
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  final pica = jsWindow.pica() as Pica?;
  if (pica == null) {
    throw Exception(
        'Pica not found. This plugin requires pica for image compression on the web. '
        'See documentation for more details https://github.com/fluttercandies/flutter_image_compress?tab=readme-ov-file#web');
  }
  logger.jsLog('The pica instance', pica);
  logger.jsLog('src image buffer', buffer);
  logger.dartLog('src image buffer length: ${buffer.length}');
  final bitmap = await buffer.toImageBitmap();

  final srcWidth = bitmap.width;
  final srcHeight = bitmap.height;

  final ratio = srcWidth / srcHeight;

  final width = srcWidth > minWidth ? minWidth : srcWidth;
  final height = width ~/ ratio;

  logger.jsLog('target size', '$width x $height');

  final canvas = HTMLCanvasElement();
  canvas.width = width;
  canvas.height = height;
  await pica.resize(bitmap, canvas).toDart;
  final blob = canvas.toDataUrl(format.type, quality / 100);
  final str = blob.split(',')[1];

  bitmap.close();
  final result = base64Decode(str);
  logger.jsLog('compressed image buffer', result);
  logger.dartLog('compressed image buffer length: ${result.length}');
  logger.dartLog('compressed took ${stopwatch.elapsedMilliseconds}ms');

  return result;
}

extension CompressExt on CompressFormat {
  String get type {
    switch (this) {
      case CompressFormat.jpeg:
        return 'image/jpeg';
      case CompressFormat.png:
        return 'image/png';
      case CompressFormat.webp:
        return 'image/webp';
      case CompressFormat.heic:
        throw UnimplementedError('heic is not support web');
      default:
        return 'image/jpeg';
    }
  }
}

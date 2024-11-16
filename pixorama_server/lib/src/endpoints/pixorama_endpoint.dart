import 'dart:typed_data'; // Mengimport pustaka untuk bekerja dengan array byte
import 'package:serverpod/serverpod.dart'; // Mengimport Serverpod, framework untuk backend Dart
import 'package:pixorama_server/src/generated/protocol.dart'; // Mengimport protokol untuk komunikasi

// Endpoint untuk mengelola data gambar (pixel art) pada server
class PixoramaEndpoint extends Endpoint {
  // Mendefinisikan ukuran gambar 64x64 piksel
  static const _imageWidth = 64;
  static const _imageHeight = 64;
  static const _numPixels = _imageWidth * _imageHeight;

  // Mendefinisikan jumlah warna dalam palet dan warna default
  static const _numColorsInPalette = 16;
  static const _defaultPixelColor = 2;

  // Membuat array data piksel dengan warna default untuk semua piksel
  final _pixelData = Uint8List(_numPixels)
    ..fillRange(0, _numPixels, _defaultPixelColor);

  // Mendefinisikan nama kanal untuk komunikasi antar sesi
  static const _channelPixelAdded = 'pixel-added';

  // Fungsi untuk mengubah warna piksel
  Future<void> setPixel(
    Session session, {
    required int colorIndex, // Warna baru untuk piksel
    required int pixelIndex, // Indeks piksel yang ingin diubah
  }) async {
    // Validasi indeks warna sesuai jumlah warna yang tersedia
    if (colorIndex < 0 || colorIndex >= _numColorsInPalette) {
      throw FormatException('colorIndex is out of range: $colorIndex');
    }

    // Validasi indeks piksel sesuai ukuran total piksel
    if (pixelIndex < 0 || pixelIndex >= _numPixels) {
      throw FormatException('pixelIndex is out of range: $pixelIndex');
    }

    // Mengubah warna piksel pada indeks yang ditentukan
    _pixelData[pixelIndex] = colorIndex;

    // Mengirimkan pesan pembaruan piksel ke kanal yang telah ditentukan
    session.messages.postMessage(
      _channelPixelAdded,
      ImageUpdate(
        pixelIndex: pixelIndex,
        colorIndex: colorIndex,
      ),
    );
  }

  // Fungsi untuk streaming pembaruan gambar ke klien
  Stream imageUpdates(Session session) async* {
    // Membuat aliran data untuk menerima pembaruan piksel
    var updateStream = 
      session.messages.createStream<ImageUpdate>(_channelPixelAdded);

    // Mengirimkan data awal gambar (64x64) dengan warna default ke klien
    yield ImageData(
      pixels: _pixelData.buffer.asByteData(),
      width: _imageWidth,
      height: _imageHeight,
    );

    // Mengirim pembaruan piksel secara real-time dari aliran
    await for (var imageUpdates in updateStream){
      yield imageUpdates;
    }
  }
}

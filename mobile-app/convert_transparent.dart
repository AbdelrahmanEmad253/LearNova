import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final transparentImage = img.Image(width: 1, height: 1, numChannels: 4);
  transparentImage.setPixelRgba(0, 0, 0, 0, 0, 0);
  final pngBytes = img.encodePng(transparentImage);
  File('assets/logo/transparent.png').writeAsBytesSync(pngBytes);
  print('Done! Saved assets/logo/transparent.png');
}

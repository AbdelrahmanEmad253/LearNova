import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading image...');
  final File file = File('assets/logo/LearNovaLogo.png');
  if (!file.existsSync()) {
    print('File not found!');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  
  print('Original dimensions: \${image.width} x \${image.height}');
  
  // To prevent Android 12 from cropping the edges, we need the actual logo to fit within the inner 2/3 of the image.
  // So we will create a new transparent image that is 2x the size, and draw the logo in the center.
  final newSize = (image.width > image.height ? image.width : image.height) * 2;
  
  final paddedImage = img.Image(width: newSize, height: newSize, numChannels: 4);
  
  // Fill with transparency
  for (int y = 0; y < paddedImage.height; y++) {
    for (int x = 0; x < paddedImage.width; x++) {
      paddedImage.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
  
  // Draw original image in center
  final startX = (newSize - image.width) ~/ 2;
  final startY = (newSize - image.height) ~/ 2;
  
  img.compositeImage(paddedImage, image, dstX: startX, dstY: startY);
  
  print('Saving as padded_splash.png...');
  final pngBytes = img.encodePng(paddedImage);
  File('assets/logo/padded_splash.png').writeAsBytesSync(pngBytes);
  print('Done! Saved assets/logo/padded_splash.png');
}

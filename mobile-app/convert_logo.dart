import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading image...');
  final File file = File('assets/logo/LearNovaLogo.jpeg');
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
  
  // Create a new transparent image with the same dimensions
  final transparentImage = img.Image(width: image.width, height: image.height, numChannels: 4);
  
  // The center and radius of the circle
  final centerX = image.width / 2;
  final centerY = image.height / 2;
  final radius = (image.width < image.height ? image.width : image.height) / 2;
  
  // Apply a circular mask
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final distance = dx * dx + dy * dy;
      
      if (distance <= radius * radius) {
        // Inside the circle, copy the pixel
        transparentImage.setPixel(x, y, image.getPixel(x, y));
      } else {
        // Outside the circle, make it completely transparent
        transparentImage.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  
  print('Saving as PNG...');
  final pngBytes = img.encodePng(transparentImage);
  File('assets/logo/LearNovaLogo.png').writeAsBytesSync(pngBytes);
  print('Done! Saved assets/logo/LearNovaLogo.png');
}

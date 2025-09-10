import 'dart:io';
import 'package:image/image.dart' as img;

/// Pads app_icon.png to a circle-safe canvas for Android 12 splash.
/// Input: assets/icons/app_icon.png (square)
/// Output: assets/icons/app_icon_android12.png
void main(List<String> args) async {
  const srcPath = 'assets/icons/app_icon.png';
  const dstPath = 'assets/icons/app_icon_android12.png';
  final file = File(srcPath);
  if (!await file.exists()) {
    stderr.writeln('Source icon not found: $srcPath');
    exit(1);
  }
  final bytes = await file.readAsBytes();
  final source = img.decodeImage(bytes);
  if (source == null) {
    stderr.writeln('Failed to decode source icon');
    exit(2);
  }
  final size = source.width < source.height ? source.width : source.height;
  // Increase padding so Android 12 circular mask won't clip the art
  // Optional arg: ratio (e.g., 1.8 means 80% bigger canvas than icon)
  final ratio = args.isNotEmpty ? double.tryParse(args.first) ?? 1.6 : 1.6;
  final canvasSize = (size * ratio).round();
  final bg = img.Image(width: canvasSize, height: canvasSize);
  // Transparent background
  img.fill(bg, color: img.ColorInt8.rgba(0, 0, 0, 0));
  // center place the source
  final dx = ((canvasSize - size) / 2).round();
  final dy = dx;
  img.compositeImage(bg, source, dstX: dx, dstY: dy);

  final out = img.encodePng(bg);
  await File(dstPath).writeAsBytes(out);
  stdout.writeln('Generated padded Android 12 splash icon: $dstPath');
}

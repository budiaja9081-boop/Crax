import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/session.dart';
import '../theme/laxx_theme.dart';

class AppBackground extends StatelessWidget {
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  final String wallKey;
  final Widget child;

  const AppBackground({super.key, this.wallKey = 'app', required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: version,
      builder: (_, v, __) => FutureBuilder<String?>(
        key: ValueKey('$wallKey-$v'),
        future: Session().getWallpaper(wallKey),
        builder: (_, snap) {
          final path = snap.data;
          final hasWall = path != null && File(path).existsSync();
          return Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Laxx.bg)),
              if (hasWall)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25,
                    child: Image.file(File(path!), fit: BoxFit.cover),
                  ),
                ),
              child,
            ],
          );
        },
      ),
    );
  }
}

Future<bool> pickWallpaper(String key) async {
  final f = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (f == null) return false;
  final docs = await getApplicationDocumentsDirectory();
  final dest = p.join(
    docs.path,
    'wall_${key}_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await File(f.path).copy(dest);
  await Session().setWallpaper(key, dest);
  AppBackground.version.value++;
  return true;
}

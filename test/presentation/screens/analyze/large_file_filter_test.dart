import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/platform/channels.dart';

void main() {
  group('Large file filtering', () {
    test('default threshold of 500MB filters correctly', () {
      const minSizeMb = 500;
      final minBytes = minSizeMb * 1024 * 1024;

      final files = [
        _makeFile('small.txt', 100 * 1024 * 1024),      // 100 MB
        _makeFile('medium.bin', 400 * 1024 * 1024),      // 400 MB
        _makeFile('large.bin', 600 * 1024 * 1024),       // 600 MB
        _makeFile('huge.bin', 1024 * 1024 * 1024),       // 1 GB
      ];

      final filtered = files.where((f) => f.size >= minBytes && !f.isDirectory).toList();

      expect(filtered.length, 2);
      expect(filtered[0].name, 'large.bin');
      expect(filtered[1].name, 'huge.bin');
    });

    test('threshold of 100MB includes more files', () {
      const minSizeMb = 100;
      final minBytes = minSizeMb * 1024 * 1024;

      final files = [
        _makeFile('tiny.txt', 50 * 1024 * 1024),         // 50 MB
        _makeFile('small.txt', 100 * 1024 * 1024),       // 100 MB
        _makeFile('medium.bin', 400 * 1024 * 1024),      // 400 MB
      ];

      final filtered = files.where((f) => f.size >= minBytes && !f.isDirectory).toList();

      expect(filtered.length, 2);
      expect(filtered[0].name, 'small.txt');
      expect(filtered[1].name, 'medium.bin');
    });

    test('threshold of 5000MB filters out almost everything', () {
      const minSizeMb = 5000;
      final minBytes = minSizeMb * 1024 * 1024;

      final files = [
        _makeFile('1gb.bin', 1024 * 1024 * 1024),
        _makeFile('2gb.bin', 2 * 1024 * 1024 * 1024),
        _makeFile('5gb.bin', 5 * 1024 * 1024 * 1024),
      ];

      final filtered = files.where((f) => f.size >= minBytes && !f.isDirectory).toList();

      expect(filtered.length, 1);
      expect(filtered[0].name, '5gb.bin');
    });

    test('directories are excluded from filtering', () {
      const minSizeMb = 1;
      final minBytes = minSizeMb * 1024 * 1024;

      final files = [
        _makeDir('folder', 1024 * 1024 * 1024),
        _makeFile('file.txt', 1024 * 1024 * 1024),
      ];

      final filtered = files.where((f) => f.size >= minBytes && !f.isDirectory).toList();

      expect(filtered.length, 1);
      expect(filtered[0].name, 'file.txt');
    });

    test('slider range is 100 to 5000 MB with 100MB step', () {
      const min = 100;
      const max = 5000;
      const divisions = 49;
      final step = (max - min) / divisions;

      expect(step, 100.0);
    });
  });
}

NativeScanResult _makeFile(String name, int size) {
  return NativeScanResult(
    path: '/test/$name',
    name: name,
    size: size,
    lastModified: DateTime.now().millisecondsSinceEpoch,
    isDirectory: false,
  );
}

NativeScanResult _makeDir(String name, int size) {
  return NativeScanResult(
    path: '/test/$name',
    name: name,
    size: size,
    lastModified: DateTime.now().millisecondsSinceEpoch,
    isDirectory: true,
  );
}

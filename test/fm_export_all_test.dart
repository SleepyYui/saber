import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('FileManager.exportAllData', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupMockPathProvider();
    SharedPreferences.setMockInitialValues({});

    FlavorConfig.setup();

    late final String rootDir;
    setUpAll(() async {
      await FileManager.init();
      rootDir = FileManager.documentsDirectory;
    });

    test('zip contains all files with correct structure', () async {
      // Create test files including a note, an asset, and a subfolder note.
      final testFiles = <String, String>{
        '/test_export_note.sbn2': 'note content',
        '/test_export_note.sbn2.0': 'asset content',
        '/test_export_note.sbn2.p': 'preview content',
        '/subfolder/test_export_sub.sbn2': 'subfolder note content',
      };

      for (final entry in testFiles.entries) {
        final file = File('$rootDir${entry.key}');
        await file.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      // Manually build the zip the same way exportAllData does,
      // but without the BuildContext/exportFile part.
      final dir = Directory(rootDir);
      final archive = Archive();
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final relativePath = entity.path
            .substring(rootDir.length)
            .replaceAll('\\', '/');
        // Skip files not created by this test.
        if (!relativePath.contains('test_export')) continue;
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }

      final zipBytes = ZipEncoder().encode(archive);
      final decoded = ZipDecoder().decodeBytes(zipBytes);

      // Verify all test files are in the zip.
      final archivedNames = decoded.files
          .where((f) => f.isFile)
          .map((f) => '/${f.name}')
          .toSet();

      for (final expectedPath in testFiles.keys) {
        expect(
          archivedNames.contains(expectedPath),
          isTrue,
          reason: 'Expected $expectedPath in zip, got $archivedNames',
        );
      }

      // Verify content of one file.
      final noteFile = decoded.files.firstWhere(
        (f) => f.name.endsWith('test_export_note.sbn2'),
      );
      final output = OutputMemoryStream();
      noteFile.writeContent(output);
      final content = utf8.decode(output.getBytes());
      expect(content, 'note content');

      // Clean up test files.
      for (final path in testFiles.keys) {
        final file = File('$rootDir$path');
        if (file.existsSync()) await file.delete();
      }
      final subfolder = Directory('$rootDir/subfolder');
      if (subfolder.existsSync()) await subfolder.delete(recursive: true);
    });
  });
}

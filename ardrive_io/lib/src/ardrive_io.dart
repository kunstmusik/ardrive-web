import 'dart:async';

import 'package:flutter/foundation.dart';

import 'file_provider.dart';
import 'io_exception.dart';
import 'io_file.dart';
import 'io_folder.dart';
import 'mobile/mobile_io.dart';
import 'web/stub_web_io.dart' // Stub implementation
    if (dart.library.html) 'web/web_io.dart';

/// API for I/O operations
///
/// Opens the platform specific file picker to pick files and folders, and save files using
/// the `IOFile` and `IOFolder` APIs.
abstract class ArDriveIO {
  Future<IOFile> pickFile(
      {List<String>? allowedExtensions, required FileSource fileSource});
  Future<List<IOFile>> pickFiles(
      {List<String>? allowedExtensions, required FileSource fileSource});
  Future<IOFolder> pickFolder();
  Future<void> saveFile(IOFile file);

  factory ArDriveIO() {
    if (kIsWeb) {
      return WebIO(
          fileAdapter: IOFileAdapter(),
          folderAdapter: IOFolderAdapter(),
          folderPicker: FolderPicker());
    }
    final adapter = IOFileAdapter();
    return MobileIO(
        fileProviderFactory: MobileFileProviderFactory(adapter),
        fileSaver: FileSaver(),
        fileAdapter: adapter,
        folderAdapter: IOFolderAdapter());
  }
}

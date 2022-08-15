import 'dart:io';

import 'package:ardrive_io/ardrive_io.dart';
import 'package:ardrive_io/src/io_exception.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart' as file_saver;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart' as mime;
import 'package:permission_handler/permission_handler.dart';

import '../file_provider.dart';

class MobileIO implements ArDriveIO {
  MobileIO(
      {required IOFileAdapter fileAdapter,
      required FileSaver fileSaver,
      required IOFolderAdapter folderAdapter,
      required MobileFileProviderFactory fileProviderFactory})
      : _fileAdapter = fileAdapter,
        _fileSaver = fileSaver,
        _folderAdapter = folderAdapter,
        _fileProviderFactory = fileProviderFactory;

  final FileSaver _fileSaver;
  final IOFileAdapter _fileAdapter;
  final IOFolderAdapter _folderAdapter;
  final MobileFileProviderFactory _fileProviderFactory;

  @override
  Future<IOFile> pickFile(
      {List<String>? allowedExtensions, required FileSource fileSource}) async {
    final provider = _fileProviderFactory.getProviderFromFileSource(fileSource);

    return provider.pickFile(allowedExtensions);
  }

  @override
  Future<List<IOFile>> pickFiles(
      {List<String>? allowedExtensions, required FileSource fileSource}) async {
    final provider = _fileProviderFactory.getProviderFromFileSource(fileSource);

    return provider.pickMultipleFiles(allowedExtensions);
  }

  @override
  Future<IOFolder> pickFolder() async {
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();

    if (selectedDirectoryPath == null) {
      throw ActionCanceledException();
    }

    final selectedDirectory = Directory(selectedDirectoryPath);

    final folder = _folderAdapter.fromFileSystemDirectory(selectedDirectory);

    return folder;
  }

  @override
  Future<void> saveFile(IOFile file) async {
    try {
      await _fileSaver.save(file);
    } catch (e) {
      rethrow;
    }
  }
}

/// Opens the file picker dialog to select the folder to save
///
/// This implementation uses the `file_saver` package.
///
/// Throws an `FileSystemPermissionDeniedException` when user deny access to storage
class MobileSelectableFolderFileSaver implements FileSaver {
  @override
  Future<void> save(IOFile file) async {
    await _requestPermissions();
    await _verifyPermissions();

    await file_saver.FileSaver.instance.saveAs(
        file.name,
        await file.readAsBytes(),
        mime.extensionFromMime(file.contentType),
        getMimeTypeFromString(file.contentType));

    return;
  }

  Future<void> _verifyPermissions() async {
    if (await Permission.storage.isGranted) {
      return;
    }

    throw FileSystemPermissionDeniedException([Permission.storage]);
  }

  /// Request permissions related to storage on `Android` and `iOS`
  Future<void> _requestPermissions() async {
    await Permission.storage.request();
  }
}

class MobileFileProviderFactory {
  MobileFileProviderFactory(this._adapter);

  final IOFileAdapter _adapter;

  FileProvider getProviderFromFileSource(FileSource fileSource) {
    switch (fileSource) {
      case FileSource.gallery:
        final imagePicker = ImagePicker();

        return GaleryProvider(imagePicker, _adapter);
      case FileSource.fileSystem:
        return FileSystemProvider(_adapter);
      default:
        throw UnsupportedPlatformException(
            'The ${fileSource.toString()} is not supported');
    }
  }
}

class GaleryProvider implements FileProvider {
  GaleryProvider(this._imagePicker, this._adapter);

  final ImagePicker _imagePicker;
  final IOFileAdapter _adapter;

  @override
  Future<IOFile> pickFile(List<String>? allowedExtensions) async {
    // Pick an image
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      throw EntityPathException();
    }

    return _adapter.fromXFile(image);
  }

  @override
  Future<List<IOFile>> pickMultipleFiles(
      List<String>? allowedExtensions) async {
    final images = await _imagePicker.pickMultiImage();

    if (images == null) {
      throw EntityPathException();
    }

    return Future.wait(images.map((image) => _adapter.fromXFile(image)));
  }
}

class FileSystemProvider implements FileProvider {
  FileSystemProvider(this._adapter);

  final IOFileAdapter _adapter;

  @override
  Future<IOFile> pickFile(List<String>? allowedExtensions) async {
    FilePickerResult result =
        await _pickFile(allowedExtensions: allowedExtensions);

    return _adapter.fromFilePicker(result.files.first);
  }

  @override
  Future<List<IOFile>> pickMultipleFiles(
      List<String>? allowedExtensions) async {
    FilePickerResult result = await _pickFile(
        allowedExtensions: allowedExtensions, allowMultiple: true);

    return Future.wait(
        result.files.map((file) => _adapter.fromFilePicker(file)).toList());
  }

  Future<FilePickerResult> _pickFile(
      {List<String>? allowedExtensions, bool allowMultiple = false}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        type: allowedExtensions == null ? FileType.any : FileType.custom);

    if (result != null) {
      return result;
    }

    throw ActionCanceledException();
  }
}

/// Defines the API for saving `IOFile` on Storage
abstract class FileSaver {
  factory FileSaver() {
    if (Platform.isAndroid || Platform.isIOS) {
      return MobileSelectableFolderFileSaver();
    }
    throw UnsupportedPlatformException(
        'The ${Platform.operatingSystem} platform is not supported');
  }

  Future<void> save(IOFile file);
}

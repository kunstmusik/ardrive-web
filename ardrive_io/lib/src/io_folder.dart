import 'dart:async';
import 'dart:io';

import 'package:ardrive_io/ardrive_io.dart';
import 'package:equatable/equatable.dart';

abstract class IOFolder extends Equatable implements IOEntity {
  Future<List<IOEntity>> listContent();
}

class _FileSystemFolder extends IOFolder {
  _FileSystemFolder._({
    required this.name,
    required this.lastModifiedDate,
    required this.path,
    required List<FileSystemEntity> folderContent,
  }) : _folderContent = folderContent;

  Future<void> initFolder() async {
    await _mountFolderChildren();
  }

  @override
  final String name;

  @override
  final DateTime lastModifiedDate;

  @override
  final String path;

  @override
  Future<List<IOEntity>> listContent() async {
    return _mountFolderChildren();
  }

  final List<FileSystemEntity> _folderContent;

  Future<List<IOEntity>> _mountFolderChildren() async {
    List<IOEntity> _children = [];

    for (var fs in _folderContent) {
      _children.add(await _addFolderNode(fs));
    }

    return _children;
  }

  Future<IOEntity> _addFolderNode(FileSystemEntity fsEntity) async {
    if (fsEntity is Directory) {
      final newNode = await IOFolderAdapter().fromFileSystemDirectory(fsEntity);

      for (var fs in fsEntity.listSync()) {
        final children = await newNode.listContent();
        children.add(await _addFolderNode(fs));
      }

      return newNode;
    }

    return IOFileAdapter().fromFile(fsEntity as File);
  }

  @override
  List<Object?> get props => [name, path];
}

class IOFolderAdapter {
  Future<IOFolder> fromFileSystemDirectory(Directory directory) async {
    final content = directory.listSync();
    final selectedDirectoryPath = directory.path;

    final folder = _FileSystemFolder._(
        name: selectedDirectoryPath.split('/').last,
        lastModifiedDate: (await directory.stat()).modified,
        path: selectedDirectoryPath,
        folderContent: content);

    await folder.initFolder();

    return folder;
  }
}

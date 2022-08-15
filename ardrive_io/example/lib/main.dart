import 'dart:io';
import 'dart:typed_data';

import 'package:ardrive_io/ardrive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ArDriveIOExample(),
    );
  }
}

class ArDriveIOExample extends StatefulWidget {
  const ArDriveIOExample({Key? key}) : super(key: key);

  @override
  State<ArDriveIOExample> createState() => _ArDriveIOExampleState();
}

class _ArDriveIOExampleState extends State<ArDriveIOExample> {
  String? fileDescription;
  IOFile? currentFile;
  IOFolder? currentFolder;
  ArDriveIO arDriveIO = ArDriveIO();

  Future<IOFile> selectFileSource(BuildContext context) async {
    final io = ArDriveIO();
    late IOFile file;
    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
            height: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ListTile(
                //   onTap: () async {
                //     files.addAll(await io.pickFiles(fileSource: FileSource.camera));
                //     Navigator.pop(context);
                //   },
                //   title: Text('Camera'),
                //   leading: Icon(Icons.camera),
                // ),
                const SizedBox(
                  height: 8,
                ),
                ListTile(
                  onTap: () async {
                    file = await io.pickFile(fileSource: FileSource.gallery);
                    Navigator.pop(context);
                  },
                  title: const Text('Gallery'),
                  leading: const Icon(Icons.image),
                ),
                const SizedBox(
                  height: 8,
                ),
                ListTile(
                    onTap: () async {
                      file =
                          await io.pickFile(fileSource: FileSource.fileSystem);

                      Navigator.pop(context);
                    },
                    title: Text('Files'),
                    leading: Icon(Icons.file_open_sharp))
              ],
            ),
          );
        });
    return file;
  }

  Future<void> pickFile() async {
    late IOFile file;

    if (Platform.isAndroid || Platform.isIOS) {
      file = await selectFileSource(context);
    } else {
      file = await arDriveIO.pickFile(fileSource: FileSource.fileSystem);
    }

    setState(() {
      currentFile = file;
      fileDescription = null;
      currentFolder = null;
    });
  }

  Future<void> pickFolder() async {
    final folder = await arDriveIO.pickFolder();
    final files = await folder.listFiles();

    setState(() {
      currentFolder = folder;
      fileDescription = files.map((e) => e.name).join('\n\n');
      currentFile = null;
    });
  }

  Future<void> saveFile(BuildContext context) async {
    // creates a new file and save on O.S.
    await arDriveIO.saveFile(currentFile!);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('File saved')));

    setState(() {
      currentFile = null;
    });
  }

  /// Creates a text file
  Future<void> createFile() async {
    final ioFile = await IOFile.fromData(
        Uint8List.fromList('ArDrive is the best! :)'.codeUnits),
        name: 'created_file.txt',
        lastModifiedDate: DateTime.now());

    await arDriveIO.saveFile(ioFile);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('File saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
            '${currentFile != null ? currentFile!.name : currentFolder != null ? currentFolder!.name : 'ArDriveIO'} '),
      ),
      body: Center(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(fileDescription ?? ''),
          ),
          ElevatedButton(
              onPressed: () async {
                await createFile();
              },
              child: const Text('Create file')),
          ElevatedButton(
              onPressed: () async {
                await pickFile();
              },
              child: const Text('Pick file')),
          ElevatedButton(
              onPressed: () async {
                await pickFolder();
              },
              child: const Text('Pick folder')),
          if (currentFile != null)
            ElevatedButton(
                onPressed: () async {
                  await saveFile(context);
                },
                child: const Text('save file')),
        ]),
      ),
    );
  }
}

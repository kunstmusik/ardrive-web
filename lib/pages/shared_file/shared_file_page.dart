import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/components/components.dart';
import 'package:ardrive/components/file_icon.dart';
import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/pages/shared_file/components/shared_file_info.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// [SharedFilePage] displays details of a shared file and controls for downloading and previewing it
/// from a parent [SharedFileCubit].
class SharedFilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: BlocBuilder<SharedFileCubit, SharedFileState>(
          builder: (context, state) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state is SharedFileLoadInProgress)
                const CircularProgressIndicator()
              else if (state is SharedFileLoadSuccess) ...{
                Flexible(
                  flex: 2,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 21,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Placeholder()],
                    ),
                  ),
                ),
                Flexible(
                  child: SizedBox(
                    width: 480,
                    child: Card(
                        margin: const EdgeInsets.all(16),
                        elevation: 21,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                height: 80,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(left: 21),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      width: 32,
                                      height: 32,
                                      child: FileIcon(
                                        dataContentType:
                                            state.file.dataContentType,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      state.file.name!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline6!
                                          .copyWith(
                                              fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.left,
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SharedFileInfo(
                                  drivePrivacy: state.fileKey != null
                                      ? DrivePrivacy.private
                                      : DrivePrivacy.public,
                                  driveId: state.file.driveId!,
                                  file: state.file,
                                  revisions: state.revisions,
                                ),
                              ),
                              ElevatedButton(
                                child: SizedBox(
                                  width: 320,
                                  child: Text(
                                    appLocalizationsOf(context)
                                        .download
                                        .toUpperCase(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                onPressed: () => promptToDownloadSharedFile(
                                  context: context,
                                  fileId: state.file.id!,
                                  fileKey: state.fileKey,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ),
                  flex: 1,
                )
              } else if (state is SharedFileNotFound) ...{
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 16),
                Text(
                  appLocalizationsOf(context).specifiedFileDoesNotExist,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildReturnToAppLink(),
              }
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnToAppLink() => TextButton(
        onPressed: () => launch('https://ardrive.io/'),
        child: Text('Learn more about ArDrive'),
      );
}

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/components/components.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:ardrive/utils/filesize.dart';
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
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.text_snippet),
                          title: Text(state.file.name!),
                          subtitle: Text(filesize(state.file.size)),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 21,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(),
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

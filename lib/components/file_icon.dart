import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/models/enums.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:flutter/material.dart';

class FileIcon extends StatelessWidget {
  final String? status;
  final String? dataContentType;

  const FileIcon({Key? key, this.status, this.dataContentType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = appLocalizationsOf(context);

    Widget icon;

    if (dataContentType == ContentType.manifest) {
      icon = const Icon(Icons.account_tree_outlined);
    } else {
      final fileType = dataContentType?.split('/').first;
      switch (fileType) {
        case 'image':
          icon = const Icon(Icons.image);
          break;
        case 'video':
          icon = const Icon(Icons.ondemand_video);
          break;
        case 'audio':
          icon = const Icon(Icons.music_note);
          break;
        default:
          icon = const Icon(Icons.insert_drive_file);
      }
    }

    if (status != null) {
      String tooltipMessage;
      Color indicatorColor;

      switch (status) {
        case TransactionStatus.pending:
          tooltipMessage = localizations.pending;
          indicatorColor = Colors.orange;
          break;
        case TransactionStatus.confirmed:
          tooltipMessage = localizations.confirmed;
          indicatorColor = Colors.green;
          break;
        case TransactionStatus.failed:
          tooltipMessage = localizations.failed;
          indicatorColor = Colors.red;
          break;
        default:
          throw ArgumentError();
      }
      return Tooltip(
        message: tooltipMessage,
        child: Stack(
          children: [
            icon,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 8,
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return icon;
    }
  }
}

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/components/components.dart';
import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/entities/string_types.dart';
import 'package:ardrive/l11n/l11n.dart';
import 'package:ardrive/models/daos/daos.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:ardrive/utils/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedFileInfo extends StatefulWidget {
  final String driveId;
  final Privacy drivePrivacy;
  final FileEntity file;
  final List<FileEntity> revisions;
  const SharedFileInfo({
    required this.driveId,
    required this.drivePrivacy,
    required this.file,
    required this.revisions,
  });

  @override
  State<SharedFileInfo> createState() => _SharedFileInfoState();
}

class _SharedFileInfoState extends State<SharedFileInfo> {
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  5.0,
                ),
                color: Colors.grey[350],
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                Tab(text: appLocalizationsOf(context).itemDetailsEmphasized),
                Tab(text: appLocalizationsOf(context).itemActivityEmphasized),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoTable(context, widget.file),
                      _buildTxTable(context, widget.file),
                    ],
                  ),
                  _buildActivityTab(context),
                ],
              ),
            )
          ],
        ),
      );

  Widget _buildInfoTable(BuildContext context, FileEntity file) => DataTable(
        // Hide the data table header.
        headingRowHeight: 0,
        dataTextStyle: Theme.of(context).textTheme.subtitle2,
        columns: const [
          DataColumn(label: Text('')),
          DataColumn(label: Text('')),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).fileID)),
            DataCell(
              CopyIconButton(
                tooltip: appLocalizationsOf(context).copyFileID,
                value: widget.file.id!,
              ),
            ),
          ]),
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).fileSize)),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(filesize(widget.file.size)),
              ),
            )
          ]),
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).lastModified)),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  yMMdDateFormatter.format(widget.file.lastModifiedDate!),
                ),
              ),
            )
          ]),
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).lastUpdated)),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  yMMdDateFormatter.format(widget.revisions.first.createdAt),
                ),
              ),
            ),
          ]),
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).dateCreated)),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  yMMdDateFormatter.format(widget.file.createdAt),
                ),
              ),
            ),
          ]),
        ],
      );

  Widget _buildTxTable(BuildContext context, FileEntity file) => DataTable(
        // Hide the data table header.

        headingRowHeight: 0,
        dataTextStyle: Theme.of(context).textTheme.subtitle2,
        columns: const [
          DataColumn(label: Text('')),
          DataColumn(label: Text('')),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).metadataTxID)),
            DataCell(
              CopyIconButton(
                tooltip: appLocalizationsOf(context).copyMetadataTxID,
                value: file.dataTxId!,
              ),
            ),
          ]),
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).dataTxID)),
            DataCell(
              CopyIconButton(
                tooltip: appLocalizationsOf(context).copyDataTxID,
                value: file.dataTxId!,
              ),
            ),
          ]),
          if (file.bundledIn != null)
            DataRow(cells: [
              DataCell(Text(appLocalizationsOf(context).bundleTxID)),
              DataCell(
                CopyIconButton(
                  tooltip: appLocalizationsOf(context).copyBundleTxID,
                  value: file.bundledIn!,
                ),
              ),
            ]),
        ],
      );

  Widget _buildActivityTab(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          final revision = widget.revisions[index];

          late Widget content;
          late Widget dateCreatedSubtitle;

          if (revision is FileRevisionWithTransactions) {
            final previewOrDownloadButton = InkWell(
              onTap: () {
                downloadOrPreviewRevision(
                  drivePrivacy: widget.drivePrivacy,
                  context: context,
                  revision: revision,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: widget.drivePrivacy == DrivePrivacy.private
                      ? [
                          Text(appLocalizationsOf(context).download),
                          SizedBox(width: 4),
                          Icon(Icons.download),
                        ]
                      : [
                          Text(appLocalizationsOf(context).preview),
                          SizedBox(width: 4),
                          Icon(Icons.open_in_new)
                        ],
                ),
              ),
            );

            content = Text(appLocalizationsOf(context).fileWasModified);

            dateCreatedSubtitle =
                Text(yMMdDateFormatter.format(revision.createdAt));
          }

          return ListTile(
            title: DefaultTextStyle(
              style: Theme.of(context).textTheme.subtitle2!,
              child: content,
            ),
            subtitle: DefaultTextStyle(
              style: Theme.of(context).textTheme.caption!,
              child: dateCreatedSubtitle,
            ),
          );
        },
        separatorBuilder: (context, index) => Divider(),
        itemCount: widget.revisions.length,
      ));
}

void downloadOrPreviewRevision({
  required String drivePrivacy,
  required BuildContext context,
  required FileEntity revision,
}) {
  if (drivePrivacy == DrivePrivacy.private) {
    promptToDownloadProfileFile(
      context: context,
      driveId: revision.driveId!,
      fileId: revision.id!,
      dataTxId: revision.dataTxId!,
    );
  } else {
    context.read<DriveDetailCubit>().launchPreview(revision.dataTxId!);
  }
}

class CopyIconButton extends StatelessWidget {
  final String value;
  final String tooltip;

  const CopyIconButton({required this.value, required this.tooltip});

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.centerRight,
        child: IconButton(
          icon: const Icon(Icons.copy, color: Colors.black54),
          tooltip: tooltip,
          onPressed: () => Clipboard.setData(ClipboardData(text: value)),
        ),
      );
}

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/components/components.dart';
import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/entities/string_types.dart';
import 'package:ardrive/models/daos/daos.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedFileInfo extends StatefulWidget {
  final String driveId;
  final Privacy drivePrivacy;
  final FileEntity file;
  const SharedFileInfo({
    required this.driveId,
    required this.drivePrivacy,
    required this.file,
  });

  @override
  State<SharedFileInfo> createState() => _SharedFileInfoState();
}

class _SharedFileInfoState extends State<SharedFileInfo> {
  @override
  Widget build(BuildContext context) => Container(
        width: 320,
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              ListTile(
                title: Text(widget.file.name!),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context
                      .read<DriveDetailCubit>()
                      .toggleSelectedItemDetails(),
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: appLocalizationsOf(context).itemDetailsEmphasized),
                  Tab(text: appLocalizationsOf(context).itemActivityEmphasized),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoTable(context, widget.file),
                        //_buildTxTable(context, widget.file),
                      ],
                    ),
                    //_buildActivityTab(context, state),
                    Container()
                  ],
                ),
              )
            ],
          ),
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
          // DataRow(cells: [
          //   DataCell(Text(appLocalizationsOf(context).fileID)),
          //   DataCell(
          //     CopyIconButton(
          //       tooltip: appLocalizationsOf(context).copyFileID,
          //       value: widget.file.id,
          //     ),
          //   ),
          // ]),
          // DataRow(cells: [
          //   DataCell(Text(appLocalizationsOf(context).fileSize)),
          //   DataCell(
          //     Align(
          //       alignment: Alignment.centerRight,
          //       child: Text(filesize(widget.file.size)),
          //     ),
          //   )
          // ]),
          // DataRow(cells: [
          //   DataCell(Text(appLocalizationsOf(context).lastModified)),
          //   DataCell(
          //     Align(
          //       alignment: Alignment.centerRight,
          //       child: Text(
          //         yMMdDateFormatter.format(widget.file.lastModifiedDate),
          //       ),
          //     ),
          //   )
          // ]),
          // DataRow(cells: [
          //   DataCell(Text(appLocalizationsOf(context).lastUpdated)),
          //   DataCell(
          //     Align(
          //       alignment: Alignment.centerRight,
          //       child: Text(
          //         yMMdDateFormatter.format(widget.file.lastUpdated),
          //       ),
          //     ),
          //   ),
          // ]),
          // DataRow(cells: [
          //   DataCell(Text(appLocalizationsOf(context).dateCreated)),
          //   DataCell(
          //     Align(
          //       alignment: Alignment.centerRight,
          //       child: Text(
          //         yMMdDateFormatter.format(widget.file.dateCreated),
          //       ),
          //     ),
          //   ),
          // ]),
        ],
      );

  Widget _buildTxTable(BuildContext context, FileEntry file) => DataTable(
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
                value: file.dataTxId,
              ),
            ),
          ]),
          DataRow(cells: [
            DataCell(Text(appLocalizationsOf(context).dataTxID)),
            DataCell(
              CopyIconButton(
                tooltip: appLocalizationsOf(context).copyDataTxID,
                value: file.dataTxId,
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

//   Widget _buildActivityTab(BuildContext context, FsEntryInfoSuccess state) =>
//       Padding(
//         padding: const EdgeInsets.only(top: 16),
//         child: BlocProvider(
//           create: (context) => FsEntryActivityCubit(
//             driveId: widget.driveId,
//             maybeSelectedItem: SelectedFile(file: widget.file),
//             driveDao: context.read<DriveDao>(),
//           ),
//           child: BlocBuilder<FsEntryActivityCubit, FsEntryActivityState>(
//             builder: (context, state) {
//               if (state is FsEntryActivitySuccess) {
//                 if (state.revisions.isNotEmpty) {
//                   return ListView.separated(
//                     itemBuilder: (BuildContext context, int index) {
//                       final revision = state.revisions[index];

//                       late Widget content;
//                       late Widget dateCreatedSubtitle;
//                       late String revisionConfirmationStatus;

//                       if (revision is FileRevisionWithTransactions) {
//                         final previewOrDownloadButton = InkWell(
//                           onTap: () {
//                             downloadOrPreviewRevision(
//                               drivePrivacy: widget.drivePrivacy,
//                               context: context,
//                               revision: revision,
//                             );
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 4),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: widget.drivePrivacy ==
//                                       DrivePrivacy.private
//                                   ? [
//                                       Text(
//                                           appLocalizationsOf(context).download),
//                                       SizedBox(width: 4),
//                                       Icon(Icons.download),
//                                     ]
//                                   : [
//                                       Text(appLocalizationsOf(context).preview),
//                                       SizedBox(width: 4),
//                                       Icon(Icons.open_in_new)
//                                     ],
//                             ),
//                           ),
//                         );

//                         switch (revision.action) {
//                           case RevisionAction.create:
//                             content = Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   appLocalizationsOf(context)
//                                       .fileWasCreatedWithName(revision.name),
//                                 ),
//                                 previewOrDownloadButton,
//                               ],
//                             );
//                             break;
//                           case RevisionAction.rename:
//                             content = Text(appLocalizationsOf(context)
//                                 .fileWasRenamed(revision.name));
//                             break;
//                           case RevisionAction.move:
//                             content =
//                                 Text(appLocalizationsOf(context).fileWasMoved);
//                             break;
//                           case RevisionAction.uploadNewVersion:
//                             content = Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(appLocalizationsOf(context)
//                                     .fileHadANewRevision),
//                                 previewOrDownloadButton,
//                               ],
//                             );
//                             break;
//                           default:
//                             content = Text(
//                                 appLocalizationsOf(context).fileWasModified);
//                         }

//                         dateCreatedSubtitle = Text(
//                             yMMdDateFormatter.format(revision.dateCreated));

//                         revisionConfirmationStatus = fileStatusFromTransactions(
//                             revision.metadataTx, revision.dataTx);
//                       }

//                       late Widget statusIcon;
//                       if (revisionConfirmationStatus ==
//                           TransactionStatus.pending) {
//                         statusIcon = Tooltip(
//                           message: appLocalizationsOf(context).pending,
//                           child: const Icon(Icons.pending),
//                         );
//                       } else if (revisionConfirmationStatus ==
//                           TransactionStatus.confirmed) {
//                         statusIcon = Tooltip(
//                           message: appLocalizationsOf(context).confirmed,
//                           child: const Icon(Icons.check),
//                         );
//                       } else if (revisionConfirmationStatus ==
//                           TransactionStatus.failed) {
//                         statusIcon = Tooltip(
//                           message: appLocalizationsOf(context).failed,
//                           child: const Icon(Icons.error_outline),
//                         );
//                       }

//                       return ListTile(
//                         title: DefaultTextStyle(
//                           style: Theme.of(context).textTheme.subtitle2!,
//                           child: content,
//                         ),
//                         subtitle: DefaultTextStyle(
//                           style: Theme.of(context).textTheme.caption!,
//                           child: dateCreatedSubtitle,
//                         ),
//                         trailing: statusIcon,
//                       );
//                     },
//                     separatorBuilder: (context, index) => Divider(),
//                     itemCount: state.revisions.length,
//                   );
//                 } else {
//                   return Center(
//                       child: Text(
//                           appLocalizationsOf(context).itemIsBeingProcesed));
//                 }
//               } else {
//                 return const Center(child: CircularProgressIndicator());
//               }
//             },
//           ),
//         ),
//       );
}

void downloadOrPreviewRevision({
  required String drivePrivacy,
  required BuildContext context,
  required FileRevisionWithTransactions revision,
}) {
  if (drivePrivacy == DrivePrivacy.private) {
    promptToDownloadProfileFile(
      context: context,
      driveId: revision.driveId,
      fileId: revision.fileId,
      dataTxId: revision.dataTxId,
    );
  } else {
    context.read<DriveDetailCubit>().launchPreview(revision.dataTxId);
  }
}

class CopyIconButton extends StatelessWidget {
  final String value;
  final String tooltip;

  CopyIconButton({required this.value, required this.tooltip});

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.centerRight,
        child: IconButton(
          icon: Icon(Icons.copy, color: Colors.black54),
          tooltip: tooltip,
          onPressed: () => Clipboard.setData(ClipboardData(text: value)),
        ),
      );
}

import 'dart:async';

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/entities/constants.dart';
import 'package:ardrive/entities/string_types.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:ardrive/utils/open_url.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'drive_detail_state.dart';

class DriveDetailCubit extends Cubit<DriveDetailState> {
  final String driveId;
  final ProfileCubit _profileCubit;
  final DriveDao _driveDao;
  final AppConfig _config;

  StreamSubscription? _folderSubscription;
  final _defaultAvailableRowsPerPage = [25, 50, 75, 100];

  DriveDetailCubit({
    required this.driveId,
    String? initialFolderId,
    required ProfileCubit profileCubit,
    required DriveDao driveDao,
    required AppConfig config,
  })  : _profileCubit = profileCubit,
        _driveDao = driveDao,
        _config = config,
        super(DriveDetailLoadInProgress()) {
    if (driveId.isEmpty) {
      return;
    }

    if (initialFolderId != null) {
      // TODO: Handle deep-linking folders of unattached drives.
      Future.microtask(() async {
        final folder = await _driveDao
            .folderById(driveId: driveId, folderId: initialFolderId)
            .getSingleOrNull();
        // Open the root folder if the deep-linked folder could not be found.

        openFolder(path: folder?.path ?? rootPath);
        // The empty string here is required to open the root folder
      });
    } else {
      openFolder(path: rootPath);
    }
  }

  void openFolder({
    required String path,
    DriveOrder contentOrderBy = DriveOrder.name,
    OrderingMode contentOrderingMode = OrderingMode.asc,
  }) async {
    emit(DriveDetailLoadInProgress());

    await _folderSubscription?.cancel();
    // For attaching drives. If drive is not found, emit state to prompt drive attach
    await _driveDao.driveById(driveId: driveId).getSingleOrNull().then((value) {
      if (value == null) {
        emit(DriveDetailLoadNotFound());
        return;
      }
    });

    _folderSubscription =
        Rx.combineLatest3<Drive, FolderWithContents, ProfileState, void>(
      _driveDao.driveById(driveId: driveId).watchSingle(),
      _driveDao.watchFolderContents(
        driveId,
        folderPath: path,
        orderBy: contentOrderBy,
        orderingMode: contentOrderingMode,
      ),
      _profileCubit.stream.startWith(ProfileCheckingAvailability()),
      (drive, folderContents, _) async {
        final state = this.state is DriveDetailLoadSuccess
            ? this.state as DriveDetailLoadSuccess
            : null;
        final profile = _profileCubit.state;

        // Set selected item to subfolder if the folder being viewed is not drive root
        final List<SelectedItem> selectedItems = [];
        if (folderContents.folder.id != drive.rootFolderId) {
          selectedItems.add(SelectedFolder(folder: folderContents.folder));
        }

        var availableRowsPerPage = _defaultAvailableRowsPerPage;

        availableRowsPerPage = calculateRowsPerPage(
          folderContents.files.length + folderContents.subfolders.length,
        );

        final rootFolderNode =
            await _driveDao.getFolderTree(driveId, drive.rootFolderId);

        if (state != null) {
          emit(
            state.copyWith(
              currentDrive: drive,
              hasWritePermissions: profile is ProfileLoggedIn &&
                  drive.ownerAddress == profile.walletAddress,
              folderInView: folderContents,
              contentOrderBy: contentOrderBy,
              contentOrderingMode: contentOrderingMode,
              rowsPerPage: availableRowsPerPage.first,
              availableRowsPerPage: availableRowsPerPage,
              selectedItems: selectedItems,
            ),
          );
        } else {
          emit(DriveDetailLoadSuccess(
            currentDrive: drive,
            hasWritePermissions: profile is ProfileLoggedIn &&
                drive.ownerAddress == profile.walletAddress,
            folderInView: folderContents,
            contentOrderBy: contentOrderBy,
            contentOrderingMode: contentOrderingMode,
            rowsPerPage: availableRowsPerPage.first,
            availableRowsPerPage: availableRowsPerPage,
            selectedItems: selectedItems,
            driveIsEmpty: rootFolderNode.isEmpty(),
            multiselect: false,
          ));
        }
      },
    ).listen((_) {});
  }

  List<int> calculateRowsPerPage(int totalEntries) {
    List<int> availableRowsPerPage;
    if (totalEntries < _defaultAvailableRowsPerPage.first) {
      availableRowsPerPage = <int>[totalEntries];
    } else {
      availableRowsPerPage = _defaultAvailableRowsPerPage;
    }
    return availableRowsPerPage;
  }

  void setRowsPerPage(int rowsPerPage) {
    switch (state.runtimeType) {
      case DriveDetailLoadSuccess:
        emit(
          (state as DriveDetailLoadSuccess).copyWith(
            rowsPerPage: rowsPerPage,
          ),
        );
    }
  }

  Future<void> selectItem(SelectedItem selectedItem) async {
    var state = this.state as DriveDetailLoadSuccess;

    state = state.multiselect
        ? state.copyWith(selectedItems: [selectedItem, ...state.selectedItems])
        : state.copyWith(selectedItems: [selectedItem]);
    if (state.currentDrive.isPublic && selectedItem is SelectedFile) {
      final fileWithRevisions = _driveDao.latestFileRevisionByFileId(
        driveId: driveId,
        fileId: selectedItem.id,
      );
      final dataTxId = (await fileWithRevisions.getSingle()).dataTxId;
      state = state.copyWith(
          selectedFilePreviewUrl:
              '${_config.defaultArweaveGatewayUrl}/$dataTxId');
    }

    emit(state);
  }

  Future<void> unselectItem(SelectedItem selectedItem) async {
    var state = this.state as DriveDetailLoadSuccess;
    final updatedSelectedItems = state.selectedItems
        .where((element) => element.id != selectedItem.id)
        .toList();
    state = state.multiselect
        ? state.copyWith(selectedItems: updatedSelectedItems)
        : state.copyWith(selectedItems: []);

    emit(state);
    // Close multiselect automatically if no file is selected
    if (state.selectedItems.isEmpty && state.multiselect) {
      state = state.copyWith(multiselect: false);
      Future.delayed(
        const Duration(milliseconds: 10),
      ).then((value) => emit(state));
    }
  }

  Future<void> launchPreview(TxID dataTxId) =>
      openUrl(url: '${_config.defaultArweaveGatewayUrl}/$dataTxId');

  void sortFolder({
    DriveOrder contentOrderBy = DriveOrder.name,
    OrderingMode contentOrderingMode = OrderingMode.asc,
  }) {
    final state = this.state as DriveDetailLoadSuccess;
    openFolder(
      path: state.folderInView.folder.path,
      contentOrderBy: contentOrderBy,
      contentOrderingMode: contentOrderingMode,
    );
  }

  void toggleSelectedItemDetails() {
    final state = this.state as DriveDetailLoadSuccess;
    emit(
      state.copyWith(showSelectedItemDetails: !state.showSelectedItemDetails),
    );
  }

  void setMultiSelect(bool multiSelect) {
    final state = this.state as DriveDetailLoadSuccess;

    // Do not close selection when something is already selected
    if (state.selectedItems.isNotEmpty) {
      emit(state.copyWith(multiselect: true));
    } else {
      emit(state.copyWith(multiselect: multiSelect));
    }
  }

  @override
  Future<void> close() {
    _folderSubscription?.cancel();
    return super.close();
  }
}

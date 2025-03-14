import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/l11n/validation_messages.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';

part 'drive_rename_state.dart';

class DriveRenameCubit extends Cubit<DriveRenameState> {
  final String driveId;

  final ArweaveService _arweave;
  final UploadService _turboUploadService;
  final DriveDao _driveDao;
  final ProfileCubit _profileCubit;

  DriveRenameCubit({
    required this.driveId,
    required ArweaveService arweave,
    required UploadService turboUploadService,
    required DriveDao driveDao,
    required ProfileCubit profileCubit,
    required SyncCubit syncCubit,
  })  : _arweave = arweave,
        _turboUploadService = turboUploadService,
        _driveDao = driveDao,
        _profileCubit = profileCubit,
        super(DriveRenameInitial()) {
    () async {
      emit(DriveRenameInitial());
    }();
  }

  Future<void> submit({
    required String newName,
  }) async {
    try {
      final profile = _profileCubit.state as ProfileLoggedIn;

      final driveKey = await _driveDao.getDriveKey(driveId, profile.cipherKey);

      if (await _profileCubit.logoutIfWalletMismatch()) {
        emit(DriveRenameWalletMismatch());
        return;
      }

      if (await _fileWithSameNameExistis(newName)) {
        final previousState = state;
        emit(DriveNameAlreadyExists(newName));
        emit(previousState);
        return;
      }

      emit(DriveRenameInProgress());

      await _driveDao.transaction(() async {
        var drive = await _driveDao.driveById(driveId: driveId).getSingle();
        drive = drive.copyWith(name: newName, lastUpdated: DateTime.now());
        final driveEntity = drive.asEntity();

        if (_turboUploadService.useTurboUpload) {
          final driveDataItem = await _arweave.prepareEntityDataItem(
            driveEntity,
            profile.wallet,
            key: driveKey,
          );
          await _turboUploadService.postDataItem(dataItem: driveDataItem);
          driveEntity.txId = driveDataItem.id;
        } else {
          final driveTx = await _arweave.prepareEntityTx(
            driveEntity,
            profile.wallet,
            driveKey,
          );
          await _arweave.postTx(driveTx);
          driveEntity.txId = driveTx.id;
        }

        driveEntity.ownerAddress = profile.walletAddress;
        await _driveDao.writeToDrive(drive);
        await _driveDao.insertDriveRevision(driveEntity.toRevisionCompanion(
          performedAction: RevisionAction.rename,
        ));
      });

      emit(DriveRenameSuccess());
    } catch (err) {
      addError(err);
    }
  }

  Future<bool> _fileWithSameNameExistis(String newName) async {
    final drivesWithName = (await _driveDao.allDrives().get())
        .where((element) => element.name == newName);

    final nameAlreadyExists = drivesWithName.isNotEmpty;

    return nameAlreadyExists;
  }

  Future<Map<String, dynamic>?> _uniqueDriveName(
      AbstractControl<dynamic> control) async {
    final drive = await _driveDao.driveById(driveId: driveId).getSingle();
    final String? newDriveName = control.value;

    if (newDriveName == drive.name) {
      return null;
    }

    // Check that the current drive does not already have a drive with the target file name.
    final drivesWithName = (await _driveDao.allDrives().get())
        .where((element) => element.name == newDriveName);
    final nameAlreadyExists = drivesWithName.isNotEmpty;

    if (nameAlreadyExists) {
      control.markAsTouched();
      return {AppValidationMessage.driveNameAlreadyPresent: true};
    }

    return null;
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    emit(DriveRenameFailure());

    super.onError(error, stackTrace);
  }
}

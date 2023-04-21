import 'dart:async';

import 'package:ardrive/authentication/ardrive_auth.dart';
import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/entities/string_types.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/utils/logger/logger.dart';
import 'package:ardrive/utils/user_utils.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'drives_state.dart';

/// [DrivesCubit] includes logic for displaying the drives attached in the app.
/// It works even if the user profile is unavailable.
class DrivesCubit extends Cubit<DrivesState> {
  final ProfileCubit _profileCubit;
  final DriveDao _driveDao;
  final ArDriveAuth _auth;

  late StreamSubscription _drivesSubscription;
  String? initialSelectedDriveId;
  DrivesCubit({
    required ArDriveAuth auth,
    this.initialSelectedDriveId,
    required ProfileCubit profileCubit,
    required DriveDao driveDao,
  })  : _profileCubit = profileCubit,
        _driveDao = driveDao,
        _auth = auth,
        super(DrivesLoadInProgress()) {
    _auth.onAuthStateChanged().listen((user) {
      logger.d('User logged in: $user');
      if (user == null) {
        logger.d('User logged out');
        cleanDrives();
      }
    });

    _drivesSubscription =
        Rx.combineLatest3<List<Drive>, List<FolderEntry>, void, List<Drive>>(
      _driveDao
          .allDrives(order: OrderBy([OrderingTerm.asc(_driveDao.drives.name)]))
          .watch(),
      _driveDao.ghostFolders().watch(),
      _profileCubit.stream.startWith(ProfileCheckingAvailability()),
      (drives, _, __) => drives,
    ).listen((drives) async {
      logger.d('Drives loaded: $drives');

      final state = this.state;

      final profile = _profileCubit.state;

      String? selectedDriveId;

      if (state is DrivesLoadSuccess && state.selectedDriveId != null) {
        selectedDriveId = state.selectedDriveId;
      } else {
        selectedDriveId = initialSelectedDriveId ??
            (drives.isNotEmpty ? drives.first.id : null);
      }

      final walletAddress =
          profile is ProfileLoggedIn ? profile.walletAddress : null;

      final ghostFolders = await _driveDao.ghostFolders().get();

      logger.i('Drives loaded: $drives');

      for (final drive in drives) {
        logger.i('Drive: $drive');
      }

      logger.d('Ghost folders: ${ghostFolders.length}');
      logger.d('profile: $profile');

      final sharedDrives =
          drives.where((d) => isDriveOwner(auth, d.ownerAddress)).toList();

      // log shared drives
      for (final drive in sharedDrives) {
        logger.d('Shared Drive: $drive');
      }

      emit(
        DrivesLoadSuccess(
          selectedDriveId: selectedDriveId,
          // If the user is not logged in, all drives are considered shared ones.
          userDrives: drives
              .where((d) => profile is ProfileLoggedIn
                  ? d.ownerAddress == walletAddress
                  : false)
              .toList(),
          sharedDrives: sharedDrives,
          drivesWithAlerts: ghostFolders.map((e) => e.driveId).toList(),
          canCreateNewDrive: _profileCubit.state is ProfileLoggedIn,
        ),
      );
    });
  }

  void selectDrive(String driveId) {
    final canCreateNewDrive = _profileCubit.state is ProfileLoggedIn;
    final state = this.state is DrivesLoadSuccess
        ? (this.state as DrivesLoadSuccess).copyWith(selectedDriveId: driveId)
        : DrivesLoadedWithNoDrivesFound(canCreateNewDrive: canCreateNewDrive);
    emit(state);
  }

  void cleanDrives() {
    initialSelectedDriveId = null;

    _driveDao.deleteDrivesAndItsChildren();

    final state = DrivesLoadSuccess(
        selectedDriveId: null,
        userDrives: const [],
        sharedDrives: const [],
        drivesWithAlerts: const [],
        canCreateNewDrive: false);

    logger.i('Drives cleaned');
    logger.d('Drives state: $state');

    emit(state);
  }

  void _resetDriveSelection(DriveID detachedDriveId) {
    final canCreateNewDrive = _profileCubit.state is ProfileLoggedIn;
    if (state is DrivesLoadSuccess) {
      final state = this.state as DrivesLoadSuccess;
      state.userDrives.removeWhere((drive) => drive.id == detachedDriveId);
      state.sharedDrives.removeWhere((drive) => drive.id == detachedDriveId);
      final firstOrNullDrive = state.userDrives.isNotEmpty
          ? state.userDrives.first.id
          : state.sharedDrives.isNotEmpty
              ? state.sharedDrives.first.id
              : null;
      if (firstOrNullDrive != null) {
        emit(state.copyWith(selectedDriveId: firstOrNullDrive));
        return;
      }
    }
    emit(DrivesLoadedWithNoDrivesFound(canCreateNewDrive: canCreateNewDrive));
  }

  Future<void> detachDrive(DriveID driveId) async {
    _resetDriveSelection(driveId);
    await Future.delayed(const Duration(seconds: 1));
    await _driveDao.deleteDriveById(driveId: driveId);
  }

  @override
  Future<void> close() {
    _drivesSubscription.cancel();
    return super.close();
  }
}

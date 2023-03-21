import 'dart:async';

import 'package:ardrive/entities/profile_types.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/arconnect/arconnect_wallet.dart';
import 'package:ardrive/services/services.dart';
import 'package:ardrive/utils/local_key_value_store.dart';
import 'package:ardrive/utils/secure_key_value_store.dart';
import 'package:arweave/arweave.dart';
import 'package:cryptography/cryptography.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'profile_state.dart';

/// [ProfileCubit] includes logic for managing the user's profile login status
/// and wallet balance.
class ProfileCubit extends Cubit<ProfileState> {
  final ArweaveService _arweave;
  final TurboService _turboService;
  final ProfileDao _profileDao;
  final Database _db;

  ProfileCubit({
    required ArweaveService arweave,
    required TurboService turboService,
    required ProfileDao profileDao,
    required Database db,
  })  : _arweave = arweave,
        _turboService = turboService,
        _profileDao = profileDao,
        _db = db,
        super(ProfileCheckingAvailability()) {
    promptToAuthenticate();
  }

  Future<bool> isCurrentProfileArConnect() async {
    final profile = await _profileDao.defaultProfile().getSingleOrNull();
    if (profile != null) {
      return profile.profileType == ProfileType.arConnect.index;
    } else {
      return false;
    }
  }

  Future<void> promptToAuthenticate() async {
    final profile = await _profileDao.defaultProfile().getSingleOrNull();
    final arconnect = ArConnectService();
    // Profile unavailable - route to new profile screen
    if (profile == null) {
      emit(ProfilePromptAdd());
      return;
    }
    // json wallet present - route to login screen
    if (profile.profileType != ProfileType.arConnect.index) {
      emit(ProfilePromptLogIn());
      return;
    }

    // ArConnect extension missing - route to profile screen
    if (!(arconnect.isExtensionPresent())) {
      emit(ProfilePromptAdd());
      return;
    }

    // ArConnect connected to expected wallet - route to login screen
    late bool hasPermissions;
    try {
      hasPermissions = await arconnect.safelyCheckPermissions();
    } catch (e) {
      print(
        '[ProfileCubit] ArConnect permissions check failed - waiting for tab focus',
      );
      hasPermissions = await arconnect.safelyGetPermissionsWhenTabFocused();
    }

    print('[ProfileCubit] ArConnect permissions check result: $hasPermissions');
    if (hasPermissions &&
        profile.walletPublicKey == await arconnect.getPublicKey()) {
      emit(ProfilePromptLogIn());
      return;
    }

    // Unexpected ArConnect state - clean up and route to profile screen
    await _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
    emit(ProfilePromptAdd());
  }

  /// Returns true if detected wallet or permissions change
  Future<bool> checkIfWalletMismatch() async {
    final profile = await _profileDao.defaultProfile().getSingleOrNull();
    final arconnect = ArConnectService();

    if (profile == null) {
      return false;
    }

    if (profile.profileType == ProfileType.arConnect.index) {
      if (!(await arconnect.safelyCheckPermissions())) {
        return true;
      }
      final currentPublicKey = await arconnect.getPublicKey();
      final savedPublicKey = profile.walletPublicKey;
      if (currentPublicKey != savedPublicKey) {
        return true;
      }
    }

    return false;
  }

  /// Returns true if a logout flow is initiated as a result of a detected wallet or permissions change
  Future<bool> logoutIfWalletMismatch() async {
    final isMismatch = await checkIfWalletMismatch();
    if (isMismatch) {
      await logoutProfile();
    }
    return isMismatch;
  }

  Future<void> unlockDefaultProfile(
    String password,
    ProfileType profileType,
  ) async {
    emit(ProfileLoggingIn());

    final profile = await _profileDao.loadDefaultProfile(password);
    final arconnect = ArConnectService();

    final walletAddress = await (profileType == ProfileType.arConnect
        ? arconnect.getWalletAddress()
        : profile.wallet.getAddress());
    final walletBalance = await _arweave.getWalletBalance(walletAddress);
    final wallet = () {
      switch (profileType) {
        case ProfileType.json:
          return profile.wallet;
        case ProfileType.arConnect:
          return ArConnectWallet();
      }
    }();

    emit(
      ProfileLoggedIn(
        username: profile.details.username,
        password: password,
        wallet: wallet,
        walletAddress: walletAddress,
        walletBalance: walletBalance,
        cipherKey: profile.key,
        useTurbo: _turboService.useTurbo,
      ),
    );
  }

  Future<void> refreshBalance() async {
    final profile = state as ProfileLoggedIn;

    final walletAddress = await profile.wallet.getAddress();
    final walletBalance = await Future.wait([
      _arweave.getWalletBalance(walletAddress),
      _arweave.getPendingTxFees(walletAddress),
    ]).then((res) => res[0] - res[1]);

    emit(profile.copyWith(walletBalance: walletBalance));
  }

  /// Removes the user's existing profile and its associated data then prompts them to add another.
  ///
  /// Works even when the user is not authenticated.
  Future<void> logoutProfile() async {
    final profile = await _profileDao.defaultProfile().getSingleOrNull();
    final arconnect = ArConnectService();

    if (profile != null && profile.profileType == ProfileType.arConnect.index) {
      try {
        await arconnect.disconnect();
      } catch (e) {
        print(e);
      }
    }

    await deleteTables();
    SecureKeyValueStore(const FlutterSecureStorage()).remove('password');
    (await LocalKeyValueStore.getInstance()).remove('biometricEnabled');

    emit(ProfileLoggingOut());

    unawaited(promptToAuthenticate());
  }

  Future<void> deleteTables() async {
    // Delete all table data.
    await _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
  }
}

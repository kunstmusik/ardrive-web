import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:arweave/arweave.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test_utils/fakes.dart';
import '../test_utils/utils.dart';

void main() {
  group('FolderCreateCubit:', () {
    late DriveDao driveDao;
    late Database db;

    late ArweaveService arweave;
    late ProfileCubit profileCubit;
    late FolderCreateCubit folderCreateCubit;

    const driveId = 'drive-id';
    const rootFolderId = 'root-folder-id';
    const rootFolderFileCount = 5;

    const nestedFolderId = 'nested-folder-id';
    const nestedFolderFileCount = 5;

    const emptyNestedFolderIdPrefix = 'empty-nested-folder-id';
    const emptyNestedFolderCount = 5;

    const testGatewayURL = 'https://arweave.net';

    setUp(() async {
      registerFallbackValue(ProfileStateFake());

      db = getTestDb();
      driveDao = db.driveDao;

      await addTestFilesToDb(
        db,
        driveId: driveId,
        emptyNestedFolderCount: emptyNestedFolderCount,
        emptyNestedFolderIdPrefix: emptyNestedFolderIdPrefix,
        rootFolderId: rootFolderId,
        rootFolderFileCount: rootFolderFileCount,
        nestedFolderId: nestedFolderId,
        nestedFolderFileCount: nestedFolderFileCount,
      );

      arweave = ArweaveService(Arweave(gatewayUrl: Uri.parse(testGatewayURL)));
      profileCubit = MockProfileCubit();

      folderCreateCubit = FolderCreateCubit(
        arweave: arweave,
        driveDao: driveDao,
        profileCubit: profileCubit,
        driveId: driveId,
        parentFolderId: nestedFolderId,
      );
    });

    tearDown(() async {
      await db.close();
    });

    blocTest<FolderCreateCubit, FolderCreateState>(
      'does nothing when submitted without valid form',
      build: () => folderCreateCubit,
      act: (bloc) => bloc.submit(),
      expect: () => [],
    );
  });
}

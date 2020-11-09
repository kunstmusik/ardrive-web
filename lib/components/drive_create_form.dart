import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/l11n/l11n.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:ardrive/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'components.dart';

Future<void> promptToCreateDrive(BuildContext context) => showDialog(
      context: context,
      builder: (BuildContext context) => DriveCreateForm(),
    );

class DriveCreateForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => DriveCreateCubit(
          arweave: context.read<ArweaveService>(),
          drivesDao: context.read<DrivesDao>(),
          profileCubit: context.read<ProfileCubit>(),
          drivesCubit: context.read<DrivesCubit>(),
        ),
        child: BlocConsumer<DriveCreateCubit, DriveCreateState>(
          listener: (context, state) {
            if (state is DriveCreateInProgress) {
              showProgressDialog(context, 'CREATING DRIVE...');
            } else if (state is DriveCreateSuccess) {
              Navigator.pop(context);
              Navigator.pop(context);
            }
          },
          builder: (context, state) => AppDialog(
            title: 'CREATE DRIVE',
            content: SizedBox(
              width: kMediumDialogWidth,
              child: ReactiveForm(
                formGroup: context.watch<DriveCreateCubit>().form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReactiveTextField(
                      formControlName: 'name',
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validationMessages: kValidationMessages,
                    ),
                    Container(height: 16),
                    ReactiveDropdownField(
                      formControlName: 'privacy',
                      decoration: const InputDecoration(labelText: 'Privacy'),
                      validationMessages: kValidationMessages,
                      items: const [
                        DropdownMenuItem(
                          value: 'public',
                          child: Text('Public'),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private'),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text('CANCEL'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text('CREATE'),
                onPressed: () => context.read<DriveCreateCubit>().submit(),
              ),
            ],
          ),
        ),
      );
}

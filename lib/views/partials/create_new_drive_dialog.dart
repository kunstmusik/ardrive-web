import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/blocs.dart';
import 'text_field_dialog.dart';

promptToCreateNewDrive(BuildContext context) async {
  final driveName = await showTextFieldDialog(
    context,
    title: 'New drive',
    fieldLabel: 'Drive name',
    confirmingActionLabel: 'CREATE',
  );

  if (driveName != null) context.bloc<DrivesBloc>().add(NewDrive(driveName));
}

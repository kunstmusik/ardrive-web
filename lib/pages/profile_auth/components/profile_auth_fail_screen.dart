import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/misc/misc.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:ardrive/utils/html/html_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_auth_shell.dart';

class ProfileAuthFailScreen extends StatelessWidget {
  const ProfileAuthFailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ProfileAuthShell(
        illustration: Image.asset(
          Resources.images.profile.profileWelcome,
          fit: BoxFit.contain,
        ),
        contentWidthFactor: 0.5,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appLocalizationsOf(context).loginFailed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 32),
            Text(
              appLocalizationsOf(context).sorryLoginFailed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                context.read<ProfileCubit>().logoutProfile();
                triggerHTMLPageReload();
                context.read<ProfileAddCubit>().promptForWallet();
              },
              child: Text(appLocalizationsOf(context).logIn),
            ),
          ],
        ),
      );
}

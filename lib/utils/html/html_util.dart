import 'dart:async';

import 'implementations/html_web.dart'
    if (dart.library.io) 'implementations/html_stub.dart' as implementation;

class TabVisibilitySingleton {
  static final TabVisibilitySingleton _singleton =
      TabVisibilitySingleton._internal();

  factory TabVisibilitySingleton() {
    return _singleton;
  }

  TabVisibilitySingleton._internal();

  bool isTabFocused() => implementation.isTabFocused();

  bool isTabVisible() => implementation.isTabVisible();

  void onTabGetsVisible(Function onFocus) =>
      implementation.onTabGetsVisible(onFocus);

  Future<void> onTabGetsFocusedFuture(Future Function() onFocus) =>
      implementation.onTabGetsFocusedFuture(onFocus);

  StreamSubscription onTabGetsFocused(Function onFocus) =>
      implementation.onTabGetsFocused(onFocus);

  Future<void> closeVisibilityChangeStream() =>
      implementation.closeVisibilityChangeStream();
}

void onArConnectWalletSwitch(Function onWalletSwitch) =>
    implementation.onWalletSwitch(onWalletSwitch);

void triggerHTMLPageReload() => implementation.reload();

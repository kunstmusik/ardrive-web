import 'dart:async';

import 'package:ardrive/services/arconnect/is_document_focused.dart';
import 'package:universal_html/html.dart';

bool isTabFocused() {
  return isDocumentFocused();
}

late StreamSubscription _onVisibilityChangeStream;

Future<void> onTabGetsFocusedFuture(FutureOr<Function> onFocus) async {
  final completer = Completer<void>();
  final subscription = onTabGetsFocused(() async {
    await onFocus;
    completer.complete();
  });
  await completer.future; // wait for the completer to be resolved
  await subscription.cancel();
}

StreamSubscription<Event> onTabGetsFocused(Function onFocus) {
  final subscription = document.onFocus.listen((event) {
    onFocus();
  });
  return subscription;
}

Future<void> closeVisibilityChangeStream() async =>
    await _onVisibilityChangeStream.cancel();

void onWalletSwitch(Function onWalletSwitch) {
  window.addEventListener('walletSwitch', (event) {
    onWalletSwitch();
  });
}

void reload() {
  window.location.reload();
}

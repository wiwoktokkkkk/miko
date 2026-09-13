import 'package:flutter/cupertino.dart';

/// Route aplikasi yang selalu menggambar halaman tujuan secara langsung.
///
/// Pada sebagian perangkat Android, kombinasi snapshot/delegated transition
/// milik [CupertinoPageRoute] dapat berhenti pada satu frame abu-abu/putih.
/// Route ini tidak memakai Hero, snapshot, maupun animasi transisi, sehingga
/// halaman detail dan reader tidak bergantung pada jalur render tersebut.
PageRoute<T> mikoRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    allowSnapshotting: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  );
}

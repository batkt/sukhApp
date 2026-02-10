import 'restore_app_icon_stub.dart'
    if (dart.library.io) 'restore_app_icon_io.dart' as impl;

Future<void> restoreAppIconOnStartup() async {
  return impl.restoreAppIconOnStartup();
}

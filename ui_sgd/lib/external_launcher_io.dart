import 'dart:io';

Future<bool> openExternalUrl(String url) async {
  try {
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url], mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [url], mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
      return true;
    }
  } catch (_) {
    return false;
  }
  return false;
}

import 'dart:io';

String? localScannerStartCommand() {
  final executable = _findScannerExecutable();
  if (executable == null) {
    return null;
  }
  final quoted = executable.path.contains(' ') ? '"${executable.path}"' : executable.path;
  return '$quoted --headless';
}

Future<bool> startLocalScannerHost() async {
  final executable = _findScannerExecutable();
  if (executable == null) {
    return false;
  }
  try {
    await Process.start(
      executable.path,
      const ['--headless'],
      mode: ProcessStartMode.detached,
      workingDirectory: executable.parent.path,
    );
    return true;
  } catch (_) {
    return false;
  }
}

File? _findScannerExecutable() {
  var current = Directory.current;
  for (var i = 0; i < 6; i++) {
    final projectDir = Directory('${current.path}${Platform.pathSeparator}windows-twain');
    final projectExecutable = File(
      '${projectDir.path}${Platform.pathSeparator}bin${Platform.pathSeparator}Debug${Platform.pathSeparator}net10.0-windows${Platform.pathSeparator}windows-twain.exe',
    );
    if (projectExecutable.existsSync()) {
      return projectExecutable;
    }

    final localExecutable = File(
      '${current.path}${Platform.pathSeparator}bin${Platform.pathSeparator}Debug${Platform.pathSeparator}net10.0-windows${Platform.pathSeparator}windows-twain.exe',
    );
    if (_basename(current.path) == 'windows-twain' && localExecutable.existsSync()) {
      return localExecutable;
    }

    if (current.parent.path == current.path) {
      break;
    }
    current = current.parent;
  }
  return null;
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? normalized : parts.last;
}

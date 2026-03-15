import 'dart:io';

String? localApiStartCommand() {
  final dir = _findApiDirectory();
  final launch = _resolveDartLaunch();
  if (dir == null || launch == null) {
    return null;
  }
  final executable = launch.executable.contains(' ')
      ? '"${launch.executable}"'
      : launch.executable;
  final args = [...launch.arguments, 'run', 'bin/server.dart'].join(' ');
  return 'cd ${dir.path}\n$executable $args';
}

Future<bool> startLocalApiServer() async {
  final dir = _findApiDirectory();
  final launch = _resolveDartLaunch();
  if (dir == null || launch == null) {
    return false;
  }

  try {
    await Process.start(
      launch.executable,
      [...launch.arguments, 'run', 'bin/server.dart'],
      workingDirectory: dir.path,
      mode: ProcessStartMode.detached,
    );
    return true;
  } catch (_) {
    return false;
  }
}

Directory? _findApiDirectory() {
  var current = Directory.current;
  for (var i = 0; i < 6; i++) {
    final direct = Directory('${current.path}${Platform.pathSeparator}sgd_api');
    if (direct.existsSync()) {
      return direct;
    }
    if (_basename(current.path) == 'sgd_api' && File('${current.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      break;
    }
    current = current.parent;
  }
  return null;
}

_LaunchCommand? _resolveDartLaunch() {
  final dartExe = _findOnPath('dart.exe');
  if (dartExe != null) {
    return _LaunchCommand(dartExe, const []);
  }

  final flutterBat = _findOnPath('flutter.bat');
  if (flutterBat != null) {
    final flutterBin = Directory(flutterBat).parent.path;
    final candidate = File('$flutterBin${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}dart.exe');
    if (candidate.existsSync()) {
      return _LaunchCommand(candidate.path, const []);
    }
  }

  final dartBat = _findOnPath('dart.bat');
  if (dartBat != null) {
    return _LaunchCommand('cmd.exe', ['/c', dartBat]);
  }

  return null;
}

String? _findOnPath(String fileName) {
  final path = Platform.environment['PATH'];
  if (path == null || path.trim().isEmpty) {
    return null;
  }
  for (final entry in path.split(';')) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final file = File('$trimmed${Platform.pathSeparator}$fileName');
    if (file.existsSync()) {
      return file.path;
    }
  }
  return null;
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? normalized : parts.last;
}

class _LaunchCommand {
  _LaunchCommand(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}

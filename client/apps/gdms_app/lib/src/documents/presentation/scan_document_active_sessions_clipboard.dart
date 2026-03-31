import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/active_scan_session.dart';

Future<void> copyActiveSessionIds(
  BuildContext context,
  List<ActiveScanSession> sessions, {
  String message = 'Se copiaron {count} sessionId al portapapeles.',
}
) async {
  final ids = sessions.map((session) => session.sessionId).join('\n');
  await Clipboard.setData(ClipboardData(text: ids));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(message.replaceFirst('{count}', sessions.length.toString())),
    ),
  );
}

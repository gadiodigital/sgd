import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../documents/domain/active_scan_session.dart';
import '../api/api_exception.dart';

final class WindowsTwainScanRepositorySessionsSupport {
  static List<ActiveScanSession> parse(http.Response response) {
    if (response.body.trim().isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const ApiException(
        'El servicio de escaneo devolvio un listado de sesiones invalido.',
      );
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ActiveScanSession.fromJson)
        .where((session) => session.sessionId.isNotEmpty)
        .toList(growable: false);
  }
}

import '../domain/active_scan_session.dart';
import 'scan_document_active_sessions_support.dart';

String? resolvePrioritySessionId(List<ActiveScanSession> sessions) {
  for (final session in sessions) {
    if (ScanDocumentActiveSessionsSupport.requiresAttention(session)) {
      return session.sessionId;
    }
  }
  return null;
}

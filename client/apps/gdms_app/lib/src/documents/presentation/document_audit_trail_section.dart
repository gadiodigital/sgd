import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/document_audit_event.dart';

/// Renders the latest audit entries associated with a document.
class DocumentAuditTrailSection extends StatelessWidget {
  const DocumentAuditTrailSection({
    required this.events,
    super.key,
  });

  final List<DocumentAuditEvent> events;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Auditoría reciente',
      subtitle: 'Últimos eventos registrados para este documento.',
      child: events.isEmpty
          ? const Text('Sin eventos de auditoría asociados por el momento.')
          : Column(
              children: events
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(event.eventType),
                        subtitle: Text(event.occurredAtLabel),
                        trailing: GdmsStatusBadge(
                          label: event.severity,
                          tone: event.severity == 'INFO'
                              ? GdmsStatusTone.info
                              : GdmsStatusTone.warning,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

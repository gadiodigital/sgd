import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/document_version_item.dart';

/// Renders the immutable version history for a document.
class DocumentVersionHistorySection extends StatelessWidget {
  const DocumentVersionHistorySection({
    required this.versions,
    required this.onDownloadRequested,
    super.key,
  });

  final List<DocumentVersionItem> versions;
  final Future<void> Function(DocumentVersionItem version) onDownloadRequested;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Versiones',
      child: versions.isEmpty
          ? const Text('No hay versiones registradas.')
          : Column(
              children: versions
                  .map(
                    (version) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onTap: () => onDownloadRequested(version),
                        title: Text('Versión ${version.versionNumber}'),
                        subtitle: Text(
                          '${version.mimeType} · ${version.uploadedAtLabel}',
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(Icons.download_outlined),
                            Text('${version.fileSizeBytes} B'),
                            Text(version.fileHashPreview),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../../infrastructure/repositories/api_document_access_repository.dart';
import '../domain/document_access_entry_record.dart';
import '../domain/document_access_user_option.dart';

/// Lets privileged users inspect and grant explicit ACL entries for a document.
class ManageDocumentAccessDialog extends StatefulWidget {
  const ManageDocumentAccessDialog({
    required this.apiClient,
    required this.sessionViewModel,
    required this.documentId,
    required this.documentTitle,
    super.key,
  });

  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;
  final String documentId;
  final String documentTitle;

  @override
  State<ManageDocumentAccessDialog> createState() =>
      _ManageDocumentAccessDialogState();
}

class _ManageDocumentAccessDialogState
    extends State<ManageDocumentAccessDialog> {
  static const _permissions = [
    'READ',
    'DOWNLOAD',
    'EDITMETADATA',
    'UPLOADVERSION',
  ];

  late final ApiDocumentAccessRepository _repository;
  List<DocumentAccessEntryRecord> _entries = const [];
  List<DocumentAccessUserOption> _users = const [];
  String? _selectedUserId;
  String _selectedPermission = 'READ';
  bool _isBusy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _repository = ApiDocumentAccessRepository(
      widget.apiClient,
      widget.sessionViewModel,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.documentTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Permisos explícitos por documento'),
              const SizedBox(height: 20),
              if (_message != null) Text(_message!),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_selectedUserId),
                      initialValue: _selectedUserId,
                      decoration: const InputDecoration(labelText: 'Usuario'),
                      items: _users
                          .map(
                            (user) => DropdownMenuItem(
                              value: user.id,
                              child: Text('${user.fullName} · ${user.email}'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _isBusy
                          ? null
                          : (value) => setState(() => _selectedUserId = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_selectedPermission),
                      initialValue: _selectedPermission,
                      decoration: const InputDecoration(labelText: 'Permiso'),
                      items: _permissions
                          .map(
                            (permission) => DropdownMenuItem(
                              value: permission,
                              child: Text(permission),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _isBusy
                          ? null
                          : (value) => setState(
                              () => _selectedPermission = value ?? 'READ',
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _selectedUserId == null || _isBusy
                        ? null
                        : _grant,
                    child: const Text('Otorgar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isBusy && _entries.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _entries.isEmpty
                    ? const Center(
                        child: Text('No hay permisos explícitos configurados.'),
                      )
                    : ListView.separated(
                        itemCount: _entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          final user = _findUser(entry.userId);
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(user?.fullName ?? entry.userId),
                            subtitle: Text(
                              '${user?.email ?? ''} · ${entry.grantedAtLabel}',
                            ),
                            trailing: Text(entry.permissionCode),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final results = await Future.wait([
        _repository.loadEntries(widget.documentId),
        _repository.loadTenantUsers(),
      ]);
      if (!mounted) {
        return;
      }

      setState(() {
        _entries = results[0] as List<DocumentAccessEntryRecord>;
        _users = results[1] as List<DocumentAccessUserOption>;
        _selectedUserId = _users.isEmpty ? null : _users.first.id;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudieron cargar los permisos documentales.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _grant() async {
    final userId = _selectedUserId;
    if (userId == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      await _repository.grant(
        documentId: widget.documentId,
        userId: userId,
        permissionCode: _selectedPermission,
      );
      if (!mounted) {
        return;
      }
      await _load();
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Permiso otorgado correctamente.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudo otorgar el permiso documental.';
        _isBusy = false;
      });
    }
  }

  DocumentAccessUserOption? _findUser(String userId) {
    for (final user in _users) {
      if (user.id == userId) {
        return user;
      }
    }

    return null;
  }
}

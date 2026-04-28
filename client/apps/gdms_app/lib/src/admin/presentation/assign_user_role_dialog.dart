import 'package:flutter/material.dart';

import '../domain/admin_role_option.dart';

/// Captures a role assignment choice for an existing organization user.
class AssignUserRoleDialog extends StatefulWidget {
  const AssignUserRoleDialog({
    required this.userFullName,
    required this.availableRoles,
    super.key,
  });

  final String userFullName;
  final List<AdminRoleOption> availableRoles;

  @override
  State<AssignUserRoleDialog> createState() => _AssignUserRoleDialogState();
}

class _AssignUserRoleDialogState extends State<AssignUserRoleDialog> {
  late String _selectedRoleCode;

  @override
  void initState() {
    super.initState();
    _selectedRoleCode = widget.availableRoles.first.code;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Asignar rol a ${widget.userFullName}'),
      content: DropdownButtonFormField<String>(
        key: ValueKey(_selectedRoleCode),
        initialValue: _selectedRoleCode,
        decoration: const InputDecoration(labelText: 'Rol disponible'),
        items: widget.availableRoles
            .map(
              (role) => DropdownMenuItem<String>(
                value: role.code,
                child: Text('${role.name} (${role.code})'),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null || value.isEmpty) {
            return;
          }

          setState(() => _selectedRoleCode = value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedRoleCode),
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}

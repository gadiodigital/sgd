import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../application/identity_management_view_model.dart';
import '../domain/tenant_user_entry.dart';
import 'assign_user_role_dialog.dart';
import 'tenant_user_card.dart';

/// Shows tenant users and allows basic identity administration.
class IdentityManagementDialog extends StatefulWidget {
  const IdentityManagementDialog({
    required this.apiClient,
    required this.sessionViewModel,
    super.key,
  });

  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;

  @override
  State<IdentityManagementDialog> createState() =>
      _IdentityManagementDialogState();
}

class _IdentityManagementDialogState extends State<IdentityManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final IdentityManagementViewModel _viewModel;
  String? _selectedRoleCode;

  @override
  void initState() {
    super.initState();
    _viewModel = IdentityManagementViewModel(
      widget.apiClient,
      widget.sessionViewModel,
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GdmsPageHeader(
                      title: 'Usuarios del tenant',
                      subtitle:
                          'Listado y alta básica de identidades del tenant actual.',
                    ),
                    const SizedBox(height: 16),
                    if (_viewModel.message != null)
                      GdmsStatusBadge(
                        label: _viewModel.message!,
                        tone: _viewModel.state == ViewState.error
                            ? GdmsStatusTone.critical
                            : GdmsStatusTone.info,
                      ),
                    const SizedBox(height: 16),
                    _buildCreateUserSection(),
                    const SizedBox(height: 16),
                    _buildUsersSection(),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCreateUserSection() {
    return GdmsSectionCard(
      title: 'Crear usuario',
      subtitle: 'Alta con contraseña temporal y rol inicial.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              validator: _validateRequired,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña temporal',
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedRoleCode),
              initialValue: _selectedRoleCode,
              decoration: const InputDecoration(labelText: 'Rol inicial'),
              items: _viewModel.roles
                  .map(
                    (role) => DropdownMenuItem<String>(
                      value: role.code,
                      child: Text('${role.name} (${role.code})'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _viewModel.isBusy
                  ? null
                  : (value) => setState(() => _selectedRoleCode = value),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Seleccioná un rol.' : null,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _viewModel.isBusy ? null : _submit,
                child: const Text('Crear usuario'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return GdmsSectionCard(
      title: 'Usuarios registrados',
      child: _viewModel.users.isEmpty
          ? const Text('No hay usuarios cargados para este tenant.')
          : Column(
              children: _viewModel.users
                  .map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TenantUserCard(
                        user: user,
                        isBusy: _viewModel.isBusy,
                        onAssignRoleRequested: () => _showAssignRoleDialog(user),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final roleCode = _selectedRoleCode;
    if (roleCode == null) {
      return;
    }

    final created = await _viewModel.createUser(
      email: _emailController.text,
      fullName: _fullNameController.text,
      temporaryPassword: _passwordController.text,
      roleCode: roleCode,
    );
    if (!created) return;

    _emailController.clear();
    _fullNameController.clear();
    _passwordController.clear();
    setState(() {
      _selectedRoleCode = _viewModel.roles.isEmpty ? null : _viewModel.roles.first.code;
    });
  }

  Future<void> _showAssignRoleDialog(TenantUserEntry user) async {
    final availableRoles = _viewModel.availableRolesFor(user);
    if (availableRoles.isEmpty) {
      _viewModel.setMessage('El usuario ya tiene todos los roles disponibles.');
      return;
    }

    final selectedRoleCode = await showDialog<String>(
      context: context,
      builder: (_) => AssignUserRoleDialog(
        userFullName: user.fullName,
        availableRoles: availableRoles,
      ),
    );

    if (selectedRoleCode == null || selectedRoleCode.isEmpty) {
      return;
    }

    await _viewModel.assignRole(userId: user.id, roleCode: selectedRoleCode);
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || !text.contains('@')) {
      return 'Ingresá un email válido.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 12) {
      return 'La contraseña temporal debe tener al menos 12 caracteres.';
    }

    return null;
  }
}

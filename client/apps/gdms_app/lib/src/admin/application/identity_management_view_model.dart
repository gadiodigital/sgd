import 'dart:collection';

import 'package:core/core.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../domain/admin_role_option.dart';
import '../domain/tenant_user_entry.dart';

/// Manages tenant user listing and basic creation from the admin UI.
final class IdentityManagementViewModel extends ViewModel {
  IdentityManagementViewModel(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  List<TenantUserEntry> _users = const [];
  List<AdminRoleOption> _roles = const [];

  UnmodifiableListView<TenantUserEntry> get users => UnmodifiableListView(_users);
  UnmodifiableListView<AdminRoleOption> get roles => UnmodifiableListView(_roles);

  Future<void> load() async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      setMessage('No hay una sesión activa para gestionar usuarios.');
      return;
    }

    try {
      await run(() async {
        final usersJson = await _apiClient.getList('/api/tenants/$tenantId/users');
        final rolesJson = await _apiClient.getList('/api/roles');
        _users = usersJson
            .cast<Map<String, dynamic>>()
            .map(TenantUserEntry.fromJson)
            .toList(growable: false);
        _roles = rolesJson
            .cast<Map<String, dynamic>>()
            .map(AdminRoleOption.fromJson)
            .toList(growable: false);
        setMessage('Usuarios del tenant sincronizados.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<bool> createUser({
    required String email,
    required String fullName,
    required String temporaryPassword,
    required String roleCode,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      setMessage('No hay una sesión activa para crear usuarios.');
      return false;
    }

    try {
      await run(() async {
        await _apiClient.postObject('/api/tenants/$tenantId/users', {
          'email': email.trim(),
          'fullName': fullName.trim(),
          'temporaryPassword': temporaryPassword,
          'initialStatus': 'PENDING',
          'roleCodes': [roleCode],
          'requirePasswordChange': true,
        });
        await load();
        setMessage('Usuario creado correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  List<AdminRoleOption> availableRolesFor(TenantUserEntry user) {
    final assignedRoles = user.roleCodes.toSet();
    return _roles
        .where((role) => !assignedRoles.contains(role.code))
        .toList(growable: false);
  }

  Future<bool> assignRole({
    required String userId,
    required String roleCode,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      setMessage('No hay una sesión activa para asignar roles.');
      return false;
    }

    try {
      await run(() async {
        await _apiClient.postObject('/api/tenants/$tenantId/users/$userId/roles', {
          'roleCode': roleCode,
        });
        await load();
        setMessage('Rol asignado correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo completar la operación de usuarios.';
  }

  String? get _tenantId => _sessionViewModel.session?.tenantId;
}

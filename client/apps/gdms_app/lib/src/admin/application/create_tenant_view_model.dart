import 'package:core/core.dart';

import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';

/// Coordinates tenant creation from the admin UI.
final class CreateTenantViewModel extends ViewModel {
  CreateTenantViewModel(this._apiClient);

  final GdmsApiClient _apiClient;

  Future<bool> createTenant({
    required String code,
    required String name,
    required String sector,
    required String primaryCountryCode,
  }) async {
    try {
      await run(() async {
        await _apiClient.postObject('/api/tenants', {
          'code': code.trim(),
          'name': name.trim(),
          'sector': sector.trim(),
          'primaryCountryCode': primaryCountryCode.trim().toUpperCase(),
        });
        setMessage('Tenant creado correctamente.');
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

    return 'No se pudo crear el tenant.';
  }
}

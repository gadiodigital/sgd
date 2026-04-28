import 'package:core/core.dart';
import 'package:http/http.dart' as http;

import '../../infrastructure/api/api_defaults.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../domain/app_identity.dart';
import '../domain/auth_session.dart';

/// Coordinates sign-in, bootstrap and authenticated session state.
final class AppSessionViewModel extends ViewModel {
  AppSessionViewModel({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client() {
    apiClient = GdmsApiClient(
      baseUrlProvider: () => _apiBaseUrl,
      accessTokenProvider: () => _session?.accessToken,
      httpClient: _httpClient,
    );
  }

  final http.Client _httpClient;
  late final GdmsApiClient apiClient;

  String _apiBaseUrl = ApiDefaults.baseUrl;
  AuthSession? _session;
  AppIdentity? _identity;

  String get apiBaseUrl => _apiBaseUrl;
  AuthSession? get session => _session;
  AppIdentity? get identity => _identity;
  bool get isAuthenticated => _session != null && _identity != null;

  void updateApiBaseUrl(String value) {
    _apiBaseUrl = ApiDefaults.normalizeBaseUrl(value);
    notifyListeners();
  }

  Future<bool> signIn({
    required String tenantCode,
    required String email,
    required String password,
  }) {
    return _authenticate(
      () => apiClient.postObject('/api/auth/token', {
        'tenantCode': tenantCode,
        'email': email,
        'password': password,
      }),
      successMessage: 'Sesion iniciada correctamente.',
    );
  }

  Future<bool> bootstrapTenantAdmin({
    required String tenantCode,
    required String email,
    required String fullName,
    required String password,
  }) {
    return _authenticate(
      () => apiClient.postObject('/api/auth/bootstrap-tenant-admin', {
        'tenantCode': tenantCode,
        'email': email,
        'fullName': fullName,
        'password': password,
      }),
      successMessage:
          'Administrador de organización inicializado correctamente.',
    );
  }

  Future<bool> bootstrapPlatformAdmin({
    required String tenantCode,
    required String email,
    required String fullName,
    required String password,
  }) {
    return _authenticate(
      () => apiClient.postObject('/api/auth/bootstrap-platform-admin', {
        'tenantCode': tenantCode,
        'email': email,
        'fullName': fullName,
        'password': password,
      }),
      successMessage: 'Platform admin inicializado correctamente.',
    );
  }

  void signOut() {
    _session = null;
    _identity = null;
    setMessage('Sesion cerrada.');
    notifyListeners();
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Future<bool> _authenticate(
    Future<Map<String, dynamic>> Function() action, {
    required String successMessage,
  }) async {
    try {
      await run(() async {
        final sessionJson = await action();
        final session = AuthSession.fromJson(sessionJson, _apiBaseUrl);
        _session = session;
        final identityJson = await apiClient.getObject('/api/auth/me');
        _identity = AppIdentity.fromJson(identityJson);
        setMessage(successMessage);
      });

      return true;
    } catch (error) {
      _session = null;
      _identity = null;
      setMessage(_mapError(error));
      notifyListeners();
      return false;
    }
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo establecer sesion con la API configurada.';
  }
}

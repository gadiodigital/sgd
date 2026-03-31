import 'package:core/core.dart';
import 'dart:collection';

import '../domain/signature_overview.dart';
import '../domain/signature_envelope_item.dart';
import '../domain/signature_repository.dart';

/// Coordinates signature dashboard state and actions.
final class SignatureViewModel extends ViewModel {
  SignatureViewModel(this._repository);

  final SignatureRepository _repository;
  SignatureOverview? _overview;
  String _query = '';
  String _statusFilter = 'ALL';

  SignatureOverview? get overview => _overview;
  String get query => _query;
  String get statusFilter => _statusFilter;

  UnmodifiableListView<SignatureEnvelopeItem> get filteredEnvelopes {
    final envelopes = _overview?.envelopes ?? const <SignatureEnvelopeItem>[];
    final normalizedQuery = _query.trim().toUpperCase();
    final filtered = envelopes.where((item) {
      final matchesStatus = _statusFilter == 'ALL' || item.status == _statusFilter;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.signerDisplayName.toUpperCase().contains(normalizedQuery) ||
          item.signerEmail.toUpperCase().contains(normalizedQuery);
      return matchesStatus && matchesQuery;
    }).toList(growable: false);
    return UnmodifiableListView(filtered);
  }

  int get filteredPendingRequests =>
      filteredEnvelopes.where((item) => item.status == 'PENDING').length;

  int get filteredSignedRequests =>
      filteredEnvelopes.where((item) => item.status == 'COMPLETED').length;

  int get filteredDigitalRequests => filteredEnvelopes
      .where((item) => item.signatureLevel == 'DIGITAL')
      .length;

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = 'ALL';
    notifyListeners();
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Firma documental sincronizada.');
    });
  }

  Future<void> completeSignature(String envelopeId) async {
    await run(() async {
      await _repository.completeSignature(envelopeId);
      _overview = await _repository.loadOverview();
      setMessage('Solicitud de firma completada correctamente.');
    });
  }

  Future<void> cancelSignature(String envelopeId, String reason) async {
    await run(() async {
      await _repository.cancelSignature(envelopeId, reason: reason);
      _overview = await _repository.loadOverview();
      setMessage('Solicitud de firma cancelada correctamente.');
    });
  }
}

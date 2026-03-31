import 'package:design_system/design_system.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:flutter/material.dart';

import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_admin_tenant_details_repository.dart';

/// Displays recent governance signals for a selected tenant.
class AdminTenantDetailsDialog extends StatefulWidget {
  const AdminTenantDetailsDialog({
    required this.repository,
    required this.tenant,
    super.key,
  });

  final ApiAdminTenantDetailsRepository repository;
  final AdminTenantSummary tenant;

  @override
  State<AdminTenantDetailsDialog> createState() =>
      _AdminTenantDetailsDialogState();
}

class _AdminTenantDetailsDialogState extends State<AdminTenantDetailsDialog> {
  AdminTenantDetails? _details;
  bool _isBusy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GdmsPageHeader(
                title: widget.tenant.name,
                subtitle:
                    '${widget.tenant.code} · ${widget.tenant.sector} · alta ${widget.tenant.createdAtLabel}',
                trailing: IconButton(
                  tooltip: 'Refrescar',
                  onPressed: _isBusy ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(height: 16),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GdmsStatusBadge(
                    label: _message!,
                    tone: _details == null
                        ? GdmsStatusTone.critical
                        : GdmsStatusTone.info,
                  ),
                ),
              if (_isBusy && _details == null)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_details != null)
                Expanded(
                  child: ListView(
                    children: [
                      _TenantMetricsRow(details: _details!),
                      const SizedBox(height: 16),
                      GdmsSectionCard(
                        title: 'Actividad reciente',
                        subtitle: 'Últimos eventos de auditoría del tenant.',
                        child: _details!.recentEvents.isEmpty
                            ? const Text(
                                'No hay eventos recientes para este tenant.',
                              )
                            : Column(
                                children: _details!.recentEvents
                                    .map(
                                      (event) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: ListTile(
                                          tileColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          title: Text(
                                            event.eventType.replaceAll('_', ' '),
                                          ),
                                          subtitle: Text(
                                            '${event.tenantCode} · ${event.occurredAtLabel}',
                                          ),
                                          trailing: GdmsStatusBadge(
                                            label: event.severity,
                                            tone: _toneFor(event.severity),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                    ],
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
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
      final details = await widget.repository.loadTenantDetails(widget.tenant);
      if (!mounted) {
        return;
      }

      setState(() {
        _details = details;
        _message = 'Detalle de tenant sincronizado.';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _message = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'No se pudo cargar el detalle del tenant.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  GdmsStatusTone _toneFor(String severity) {
    return switch (severity) {
      'CRITICAL' => GdmsStatusTone.critical,
      'WARNING' || 'ERROR' => GdmsStatusTone.warning,
      _ => GdmsStatusTone.info,
    };
  }
}

class _TenantMetricsRow extends StatelessWidget {
  const _TenantMetricsRow({required this.details});

  final AdminTenantDetails details;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 180,
          child: GdmsMetricTile(
            label: 'Eventos',
            value: '${details.totalEvents}',
            color: const Color(0xFF1565C0),
          ),
        ),
        SizedBox(
          width: 180,
          child: GdmsMetricTile(
            label: 'Warnings',
            value: '${details.warningEvents}',
            color: const Color(0xFFF57F17),
          ),
        ),
        SizedBox(
          width: 180,
          child: GdmsMetricTile(
            label: 'Críticos',
            value: '${details.criticalEvents}',
            color: const Color(0xFFC62828),
          ),
        ),
        SizedBox(
          width: 180,
          child: GdmsMetricTile(
            label: 'Failed logins 24h',
            value: '${details.failedLogins24h}',
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}

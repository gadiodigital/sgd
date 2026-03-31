import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/tenant_user_entry.dart';

/// Renders one tenant user with current roles and quick actions.
class TenantUserCard extends StatelessWidget {
  const TenantUserCard({
    required this.user,
    required this.isBusy,
    required this.onAssignRoleRequested,
    super.key,
  });

  final TenantUserEntry user;
  final bool isBusy;
  final VoidCallback onAssignRoleRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(user.email),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GdmsStatusBadge(
                    label: user.status,
                    tone: user.status == 'ACTIVE'
                        ? GdmsStatusTone.info
                        : GdmsStatusTone.warning,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isBusy ? null : onAssignRoleRequested,
                    child: const Text('Asignar rol'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.roleCodes
                .map(
                  (roleCode) => GdmsStatusBadge(
                    label: roleCode,
                    tone: GdmsStatusTone.neutral,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

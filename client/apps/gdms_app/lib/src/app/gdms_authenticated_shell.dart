import 'package:feature_admin/feature_admin.dart';
import 'package:feature_audit/feature_audit.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_config/feature_config.dart';
import 'package:feature_documents/feature_documents.dart';
import 'package:feature_integrations/feature_integrations.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:feature_records/feature_records.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:feature_search/feature_search.dart';
import 'package:feature_sector_corporate/feature_sector_corporate.dart';
import 'package:feature_sector_legal/feature_sector_legal.dart';
import 'package:feature_sector_real_estate/feature_sector_real_estate.dart';
import 'package:feature_signature/feature_signature.dart';
import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import '../corporate/presentation/corporate_record_file_details_dialog.dart';
import '../corporate/presentation/create_corporate_record_file_dialog.dart';
import '../infrastructure/repositories/api_admin_repository.dart';
import '../infrastructure/repositories/api_audit_repository.dart';
import '../infrastructure/repositories/api_auth_overview_repository.dart';
import '../infrastructure/repositories/api_corporate_dashboard_repository.dart';
import '../infrastructure/repositories/api_documents_repository.dart';
import '../infrastructure/repositories/api_integrations_repository.dart';
import '../infrastructure/repositories/api_legal_dashboard_repository.dart';
import '../infrastructure/repositories/api_notifications_repository.dart';
import '../infrastructure/repositories/api_real_estate_dashboard_repository.dart';
import '../infrastructure/repositories/api_records_repository.dart';
import '../infrastructure/repositories/api_reports_repository.dart';
import '../infrastructure/repositories/api_search_repository.dart';
import '../infrastructure/repositories/api_signature_repository.dart';
import '../infrastructure/repositories/api_workflow_repository.dart';
import '../infrastructure/repositories/firebase_config_repository.dart';
import '../legal/presentation/case_file_details_dialog.dart';
import '../legal/presentation/create_case_file_dialog.dart';
import '../real_estate/presentation/create_property_file_dialog.dart';
import '../real_estate/presentation/property_file_details_dialog.dart';
import '../records/presentation/records_item_management_dialog.dart';
import 'gdms_authenticated_shell_admin.dart';
import 'gdms_authenticated_shell_documents.dart';
import 'gdms_authenticated_shell_integrations.dart';
import 'gdms_authenticated_shell_notifications.dart';
import 'gdms_authenticated_shell_reports.dart';
import 'gdms_authenticated_shell_search.dart';
import 'gdms_authenticated_shell_signature.dart';
import 'gdms_home_shell.dart';
import 'gdms_authenticated_shell_workflow.dart';

/// Composes the authenticated experience and wires the feature view models.
class GdmsAuthenticatedShell extends StatelessWidget {
  const GdmsAuthenticatedShell({
    required this.sessionViewModel,
    required this.firebaseRuntimeState,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final FirebaseRuntimeState firebaseRuntimeState;
  Future<void> _showDialog(BuildContext context, WidgetBuilder builder) {
    return showDialog<void>(context: context, builder: builder);
  }

  @override
  Widget build(BuildContext context) {
    final documentsViewModel = DocumentsViewModel(
      ApiDocumentsRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final recordsViewModel = RecordsViewModel(
      ApiRecordsRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final configViewModel = ConfigViewModel(
      FirebaseConfigRepository(firebaseRuntimeState, sessionViewModel),
    );
    final integrationsViewModel = IntegrationsViewModel(
      ApiIntegrationsRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final notificationsViewModel = NotificationsViewModel(
      ApiNotificationsRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final reportsViewModel = ReportsViewModel(
      ApiReportsRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final searchViewModel = SearchViewModel(
      ApiSearchRepository(
        sessionViewModel.apiClient,
        sessionViewModel,
        firebaseRuntimeState,
      ),
    );
    final signatureViewModel = SignatureViewModel(
      ApiSignatureRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final legalViewModel = LegalDashboardViewModel(
      ApiLegalDashboardRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final corporateViewModel = CorporateDashboardViewModel(
      ApiCorporateDashboardRepository(
        sessionViewModel.apiClient,
        sessionViewModel,
      ),
    );
    final realEstateViewModel = RealEstateDashboardViewModel(
      ApiRealEstateDashboardRepository(
        sessionViewModel.apiClient,
        sessionViewModel,
      ),
    );
    final auditViewModel = AuditOverviewViewModel(
      ApiAuditRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final workflowViewModel = WorkflowViewModel(
      ApiWorkflowRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final adminViewModel = AdminOverviewViewModel(
      ApiAdminRepository(sessionViewModel.apiClient, sessionViewModel),
    );
    final corporateRepository = ApiCorporateDashboardRepository(
      sessionViewModel.apiClient,
      sessionViewModel,
    );
    final realEstateRepository = ApiRealEstateDashboardRepository(
      sessionViewModel.apiClient,
      sessionViewModel,
    );

    return GdmsHomeShell(
      sessionViewModel: sessionViewModel,
      authPage: AuthDashboardPage(
        viewModel: AuthOverviewViewModel(
          ApiAuthOverviewRepository(sessionViewModel),
        ),
      ),
      documentsPage: buildDocumentsPage(
        sessionViewModel: sessionViewModel,
        documentsViewModel: documentsViewModel,
        showDialog: _showDialog,
      ),
      notificationsPage: buildNotificationsPage(
        notificationsViewModel: notificationsViewModel,
        sessionViewModel: sessionViewModel,
        showDialog: _showDialog,
      ),
      configPage: ConfigDashboardPage(viewModel: configViewModel),
      integrationsPage: buildIntegrationsPage(
        integrationsViewModel: integrationsViewModel,
        sessionViewModel: sessionViewModel,
        firebaseRuntimeState: firebaseRuntimeState,
        showDialog: _showDialog,
      ),
      reportsPage: buildReportsPage(
        reportsViewModel: reportsViewModel,
        sessionViewModel: sessionViewModel,
        firebaseRuntimeState: firebaseRuntimeState,
        showDialog: _showDialog,
      ),
      searchPage: buildSearchPage(
        sessionViewModel: sessionViewModel,
        searchViewModel: searchViewModel,
        showDialog: _showDialog,
      ),
      signaturePage: buildSignaturePage(
        sessionViewModel: sessionViewModel,
        signatureViewModel: signatureViewModel,
        showDialog: _showDialog,
      ),
      legalPage: LegalDashboardPage(
        viewModel: legalViewModel,
        onCreateRequested: (pageContext) async {
          await _showDialog(
            pageContext,
            (_) => CreateCaseFileDialog(
              sessionViewModel: sessionViewModel,
              onCreated: legalViewModel.load,
            ),
          );
          await legalViewModel.load();
        },
        onCaseSelected: (pageContext, caseFile) {
          return _showDialog(
            pageContext,
            (_) => CaseFileDetailsDialog(
              sessionViewModel: sessionViewModel,
              caseFile: caseFile,
            ),
          );
        },
      ),
      realEstatePage: RealEstateDashboardPage(
        viewModel: realEstateViewModel,
        onCreateRequested: (pageContext) async {
          await _showDialog(
            pageContext,
            (_) => CreatePropertyFileDialog(
              sessionViewModel: sessionViewModel,
              onCreated: realEstateViewModel.load,
            ),
          );
          await realEstateViewModel.load();
        },
        onFileSelected:
            (BuildContext pageContext, RealEstateFileItem item) async {
              final selectedItemId = item.id;
              final propertyFiles = await realEstateRepository
                  .loadPropertyFiles();
              if (propertyFiles.isEmpty) {
                return;
              }
              var selected = propertyFiles.first;
              for (final candidate in propertyFiles) {
                if (candidate.id == selectedItemId) {
                  selected = candidate;
                  break;
                }
              }

              if (!pageContext.mounted) {
                return;
              }
              await _showDialog(
                pageContext,
                (_) => PropertyFileDetailsDialog(
                  sessionViewModel: sessionViewModel,
                  propertyFile: selected,
                ),
              );
              await realEstateViewModel.load();
            },
      ),
      corporatePage: CorporateDashboardPage(
        viewModel: corporateViewModel,
        onCreateRequested: (pageContext) async {
          await _showDialog(
            pageContext,
            (_) => CreateCorporateRecordFileDialog(
              sessionViewModel: sessionViewModel,
              onCreated: corporateViewModel.load,
            ),
          );
          await corporateViewModel.load();
        },
        onRecordSelected:
            (BuildContext pageContext, CorporateRecordItem item) async {
              final recordFiles = await corporateRepository
                  .loadCorporateRecordFiles();
              if (recordFiles.isEmpty) {
                return;
              }
              var selected = recordFiles.first;
              for (final candidate in recordFiles) {
                if (candidate.id == item.id) {
                  selected = candidate;
                  break;
                }
              }

              if (!pageContext.mounted) {
                return;
              }
              await _showDialog(
                pageContext,
                (_) => CorporateRecordFileDetailsDialog(
                  sessionViewModel: sessionViewModel,
                  recordFile: selected,
                ),
              );
              await corporateViewModel.load();
            },
      ),
      auditPage: AuditDashboardPage(viewModel: auditViewModel),
      workflowPage: buildWorkflowPage(
        sessionViewModel: sessionViewModel,
        workflowViewModel: workflowViewModel,
        showDialog: _showDialog,
      ),
      recordsPage: RecordsDashboardPage(
        viewModel: recordsViewModel,
        onManageRequested: (pageContext, item) async {
          await _showDialog(
            pageContext,
            (_) => RecordsItemManagementDialog(
              apiClient: sessionViewModel.apiClient,
              sessionViewModel: sessionViewModel,
              item: item,
            ),
          );
          await recordsViewModel.load();
        },
      ),
      adminPage: buildAdminPage(
        sessionViewModel: sessionViewModel,
        firebaseRuntimeState: firebaseRuntimeState,
        adminViewModel: adminViewModel,
        showDialog: _showDialog,
      ),
    );
  }
}

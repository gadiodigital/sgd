import 'package:feature_signature/feature_signature.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../signature/application/create_signature_request_view_model.dart';
import '../signature/presentation/create_signature_request_dialog.dart';

Widget buildSignaturePage({
  required AppSessionViewModel sessionViewModel,
  required SignatureViewModel signatureViewModel,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return SignatureDashboardPage(
    viewModel: signatureViewModel,
    onCreateRequested: (pageContext) async {
      await showDialog(
        pageContext,
        (_) => CreateSignatureRequestDialog(
          viewModel: CreateSignatureRequestViewModel(
            sessionViewModel: sessionViewModel,
          ),
        ),
      );
      await signatureViewModel.load();
    },
  );
}

import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../auth/presentation/sign_in_page.dart';
import '../config/application/firebase_runtime_state.dart';
import 'gdms_authenticated_shell.dart';

/// Switches between the sign-in flow and the authenticated shell.
class GdmsRootPage extends StatelessWidget {
  const GdmsRootPage({
    required this.sessionViewModel,
    required this.firebaseRuntimeState,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final FirebaseRuntimeState firebaseRuntimeState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessionViewModel,
      builder: (context, _) {
        if (!sessionViewModel.isAuthenticated) {
          return SignInPage(sessionViewModel: sessionViewModel);
        }

        return GdmsAuthenticatedShell(
          sessionViewModel: sessionViewModel,
          firebaseRuntimeState: firebaseRuntimeState,
        );
      },
    );
  }
}

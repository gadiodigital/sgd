import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import 'gdms_root_page.dart';

/// Bootstraps the GDMS Flutter application.
class GdmsApp extends StatefulWidget {
  const GdmsApp({super.key});

  @override
  State<GdmsApp> createState() => _GdmsAppState();
}

class _GdmsAppState extends State<GdmsApp> {
  late final FirebaseRuntimeState _firebaseRuntimeState;
  late final AppSessionViewModel _sessionViewModel;

  @override
  void initState() {
    super.initState();
    _firebaseRuntimeState = FirebaseRuntimeState();
    _sessionViewModel = AppSessionViewModel();
  }

  @override
  void dispose() {
    _sessionViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GDMS Argentina',
      debugShowCheckedModeBanner: false,
      theme: GdmsTheme.light(),
      home: GdmsRootPage(
        sessionViewModel: _sessionViewModel,
        firebaseRuntimeState: _firebaseRuntimeState,
      ),
    );
  }
}

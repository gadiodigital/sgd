import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/app_session_view_model.dart';
import 'sign_in_hint_line.dart';

/// Provides the initial sign-in and bootstrap entry point to the GDMS app.
class SignInPage extends StatefulWidget {
  const SignInPage({required this.sessionViewModel, super.key});

  final AppSessionViewModel sessionViewModel;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiUrlController;
  final _tenantCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(
      text: widget.sessionViewModel.apiBaseUrl,
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _tenantCodeController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListenableBuilder(
                listenable: widget.sessionViewModel,
                builder: (context, _) {
                  return ListView(
                    children: [
                      const GdmsPageHeader(
                        title: 'Ingreso al GDMS',
                        subtitle:
                            'Conecta la app Flutter con el backend .NET para '
                            'operar tenants, documentos y records reales.',
                      ),
                      const SizedBox(height: 24),
                      GdmsSectionCard(
                        title: 'Modo de acceso',
                        subtitle:
                            'Usa login normal o bootstrap inicial cuando la '
                            'plataforma todavia no tiene administradores.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SegmentedButton<_AuthMode>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(
                                  value: _AuthMode.signIn,
                                  label: Text('Login'),
                                ),
                                ButtonSegment(
                                  value: _AuthMode.bootstrapTenantAdmin,
                                  label: Text('Tenant admin'),
                                ),
                                ButtonSegment(
                                  value: _AuthMode.bootstrapPlatformAdmin,
                                  label: Text('Platform admin'),
                                ),
                              ],
                              selected: {_mode},
                              onSelectionChanged: (selection) {
                                setState(() => _mode = selection.first);
                              },
                            ),
                            const SizedBox(height: 18),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _apiUrlController,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                      labelText: 'URL API backend',
                                      hintText: 'http://localhost:5012',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ingresa la URL base de la API.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _tenantCodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Codigo de tenant',
                                      hintText: 'DELTA-LAW',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ingresa el codigo de tenant.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          !value.contains('@')) {
                                        return 'Ingresa un email valido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_requiresFullName) ...[
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _fullNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre completo',
                                      ),
                                      validator: (value) {
                                        if (!_requiresFullName) {
                                          return null;
                                        }
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Ingresa el nombre completo.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().length < 8) {
                                        return 'Ingresa una password valida.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FilledButton.icon(
                                      onPressed: widget.sessionViewModel.isBusy
                                          ? null
                                          : _submit,
                                      icon: widget.sessionViewModel.isBusy
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.login),
                                      label: Text(_buttonLabel),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GdmsSectionCard(
                        title: 'Contexto de entorno',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthHintLine(
                              label: 'Backend local .NET',
                              value: 'http://localhost:5012',
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Si corres Flutter en Android emulator, usa '
                              'http://10.0.2.2:5012 como URL API.',
                            ),
                            if (widget.sessionViewModel.message != null) ...[
                              const SizedBox(height: 14),
                              GdmsStatusBadge(
                                label: widget.sessionViewModel.message!,
                                tone:
                                    widget.sessionViewModel.state ==
                                        ViewState.error
                                    ? GdmsStatusTone.critical
                                    : GdmsStatusTone.info,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _requiresFullName => _mode != _AuthMode.signIn;

  String get _buttonLabel {
    return switch (_mode) {
      _AuthMode.signIn => 'Ingresar',
      _AuthMode.bootstrapTenantAdmin => 'Crear tenant admin',
      _AuthMode.bootstrapPlatformAdmin => 'Crear platform admin',
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.sessionViewModel.updateApiBaseUrl(_apiUrlController.text);

    switch (_mode) {
      case _AuthMode.signIn:
        await widget.sessionViewModel.signIn(
          tenantCode: _tenantCodeController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      case _AuthMode.bootstrapTenantAdmin:
        await widget.sessionViewModel.bootstrapTenantAdmin(
          tenantCode: _tenantCodeController.text.trim(),
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          password: _passwordController.text,
        );
      case _AuthMode.bootstrapPlatformAdmin:
        await widget.sessionViewModel.bootstrapPlatformAdmin(
          tenantCode: _tenantCodeController.text.trim(),
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          password: _passwordController.text,
        );
    }
  }
}

enum _AuthMode { signIn, bootstrapTenantAdmin, bootstrapPlatformAdmin }

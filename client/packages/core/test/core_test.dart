import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

void main() {
  test('run finishes in success state when action completes', () async {
    final viewModel = _SampleViewModel();

    await viewModel.succeed();

    expect(viewModel.state, ViewState.success);
    expect(viewModel.message, 'ok');
  });

  test('run finishes in error state when action throws', () async {
    final viewModel = _SampleViewModel();

    await viewModel.fail();

    expect(viewModel.state, ViewState.error);
  });
}

final class _SampleViewModel extends ViewModel {
  Future<void> succeed() async {
    await run(() async {
      setMessage('ok');
    });
  }

  Future<void> fail() async {
    try {
      await run(() async => throw StateError('boom'));
    } on StateError {
      // The test verifies the terminal state after an exception path.
    }
  }
}

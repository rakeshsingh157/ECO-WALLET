// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:eco_wallet/main.dart';

void main() {
  testWidgets('EcoWalletApp builds smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EcoWalletApp());
  });
}


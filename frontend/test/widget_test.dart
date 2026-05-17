import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  testWidgets('TravelPick opens on the welcome screen', (tester) async {
    await AuthService.instance.init();
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('TravelPick'), findsOneWidget);
    expect(find.textContaining('Out There'), findsOneWidget);
    expect(find.text('Log In / Sign Up'), findsOneWidget);
  });
}

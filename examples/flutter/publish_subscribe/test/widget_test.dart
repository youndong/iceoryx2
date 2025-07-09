// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:iceoryx2_flutter_examples/main.dart';

void main() {
  testWidgets('App selector screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Iceoryx2ExampleApp());

    // Verify that the main screen has the expected title.
    expect(find.text('iceoryx2 Flutter Example'), findsOneWidget);

    // Verify that the publisher and subscriber buttons are present.
    expect(find.text('Publisher'), findsOneWidget);
    expect(find.text('Subscriber (Event-Driven)'), findsOneWidget);
  });
}

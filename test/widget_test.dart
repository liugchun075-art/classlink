// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:classlink/main.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that login screen is shown
    expect(find.text('登录'), findsOneWidget);
    expect(find.text('角色'), findsOneWidget);
    expect(find.text('课堂码'), findsOneWidget);
    expect(find.text('姓名'), findsOneWidget);
  });
}

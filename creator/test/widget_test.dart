// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:creator/main.dart';
import 'package:creator/features/items/application/item_service.dart';
import 'package:creator/features/items/data/in_memory_item_repository.dart';

void main() {
  testWidgets('renders catalog creator home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CreatorApp(itemService: ItemService(InMemoryItemRepository())),
    );

    expect(find.text('Catalog Creator'), findsOneWidget);
  });
}

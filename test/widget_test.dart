import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/theme_controller.dart';

void main() {
  testWidgets('Expense Tracker loads', (
    WidgetTester tester,
  ) async {
    final databaseService = DatabaseService();
    final themeController = ThemeController();

    await databaseService.init();

    await tester.pumpWidget(
      ExpenseTrackerApp(
        databaseService: databaseService,
        themeController: themeController,
      ),
    );

    expect(
      find.text('Expense Tracker'),
      findsOneWidget,
    );

    expect(
      find.text('Total Balance'),
      findsOneWidget,
    );
  });
}
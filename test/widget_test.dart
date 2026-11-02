
import 'package:flutter_test/flutter_test.dart';
import 'package:contact_app/contact_app.dart';

void main() {
  testWidgets('Contact Manager app loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(const ContactApp());

        expect(find.text('Contact Manager'), findsOneWidget);
        expect(find.text('Add Contact'), findsOneWidget);
        expect(find.text('All Contacts'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
      });
}

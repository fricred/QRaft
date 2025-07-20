import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/shared/widgets/glass_button.dart';

void main() {
  group('GlassButton Tests', () {
    testWidgets('renders with correct text', (WidgetTester tester) async {
      const testText = 'Test Button';
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: testText,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
      expect(wasPressed, false);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Test Button',
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Test Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);
    });

    testWidgets('does not call onPressed when isLoading is true', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Test Button',
              onPressed: () => wasPressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();

      expect(wasPressed, false);
    });

    testWidgets('respects custom width and height', (WidgetTester tester) async {
      const customWidth = 200.0;
      const customHeight = 48.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Test Button',
              onPressed: () {},
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      
      expect(container.constraints?.maxWidth, customWidth);
      expect(container.constraints?.maxHeight, customHeight);
    });

    testWidgets('applies custom gradient colors', (WidgetTester tester) async {
      const customColors = [Colors.red, Colors.blue];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Test Button',
              onPressed: () {},
              gradientColors: customColors,
            ),
          ),
        ),
      );

      // Verify the button renders without errors when custom colors are provided
      expect(find.byType(GlassButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('has correct default values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      final glassFinder = find.byType(GlassButton);
      final GlassButton glassButton = tester.widget(glassFinder);
      
      expect(glassButton.height, 56);
      expect(glassButton.fontSize, 18);
      expect(glassButton.fontWeight, FontWeight.w600);
      expect(glassButton.textColor, Colors.white);
      expect(glassButton.isLoading, false);
    });

    testWidgets('does not call onPressed when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Test Button',
              onPressed: null,
            ),
          ),
        ),
      );

      // Should not throw an error when tapping disabled button
      await tester.tap(find.byType(GlassButton));
      await tester.pump();
      
      expect(find.byType(GlassButton), findsOneWidget);
    });
  });

  group('PrimaryGlassButton Tests', () {
    testWidgets('renders with primary styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryGlassButton(
              text: 'Primary Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.byType(GlassButton), findsOneWidget);
    });

    testWidgets('passes through loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryGlassButton(
              text: 'Primary Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SecondaryGlassButton Tests', () {
    testWidgets('renders with secondary styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryGlassButton(
              text: 'Secondary Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Secondary Button'), findsOneWidget);
      expect(find.byType(GlassButton), findsOneWidget);
    });
  });

  group('SuccessGlassButton Tests', () {
    testWidgets('renders with success styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessGlassButton(
              text: 'Success Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Success Button'), findsOneWidget);
      expect(find.byType(GlassButton), findsOneWidget);
    });
  });
}
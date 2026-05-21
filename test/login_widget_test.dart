import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitfoco/login.dart';

Widget buildTestable() {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(680, 900)),
      child: LoginPage(),
    ),
  );
}

void main() {
  testWidgets('botão entrar sem email mostra erro', (tester) async {
    tester.view.physicalSize = const Size(680, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestable());
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    expect(find.text('Informe um e-mail.'), findsOneWidget);
  });

  testWidgets('campo de senha existe na tela', (tester) async {
    tester.view.physicalSize = const Size(680, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestable());
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
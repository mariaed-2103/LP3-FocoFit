import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitfoco/app.dart';

void main() {
  group('Testes de Integração e Regressão (Aula 09) — Rotas do App', () {
    
    testWidgets('Deve iniciar na rota de Login por padrão e encontrar os elementos estruturais', (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 3.0; 
      addTearDown(tester.view.resetPhysicalSize);

      // Arrange 
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Act 
      final botaoCriarConta = find.text('CRIAR CONTA');

      // Assert 
      expect(find.byType(TextField), findsNWidgets(2)); 
      expect(botaoCriarConta, findsOneWidget);
    });

    testWidgets('Regressão: Deve navegar para a rota de Registro ao clicar em Criar Conta', (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Arrange
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Act 
      await tester.tap(find.text('CRIAR CONTA'));
      await tester.pumpAndSettle(); 

      // Assert 
      expect(find.text('REGISTRAR'), findsOneWidget);
      expect(find.text('VOLTAR'), findsOneWidget);
    });
  });
}
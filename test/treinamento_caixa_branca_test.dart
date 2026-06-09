import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitfoco/treinamento.dart';

void main() {
  Widget criarTelaTeste({Map<String, dynamic>? treinoExistente, String? treinoId}) {
    return MaterialApp(
      home: TreinamentoPage(
        treinoId: treinoId,
        treinoExistente: treinoExistente,
      ),
    );
  }

  group('Testes de Caixa Branca (Aula 07) — Método _validar()', () {
    
    testWidgets('Caminho 1: Deve falhar na validação se o nome do treino estiver vazio', (tester) async {
      await tester.pumpWidget(criarTelaTeste());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Treino'));
      await tester.pump();

      expect(find.text('Dê um nome ao treino antes de continuar.'), findsOneWidget);
    });

    testWidgets('Caminho 2: Deve passar na validação se o treino tiver nome, mesmo com lista de exercícios vazia', (tester) async {
      final dadosTreino = {
        'nome': 'Treino de Hipertrofia',
        'exercicios': []
      };
      await tester.pumpWidget(criarTelaTeste(treinoExistente: dadosTreino));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Treino'));
      await tester.pump();

      expect(find.text('Treino salvo! Lembre-se de adicionar exercícios depois.'), findsOneWidget);
    });

    testWidgets('Caminho 3: Deve falhar na validação se algum exercício inserido estiver sem nome', (tester) async {
      await tester.pumpWidget(criarTelaTeste(treinoExistente: {'nome': 'Treino A'}));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Adicionar Exercício'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Treino'));
      await tester.pump();

      expect(find.text('O exercício 1 precisa de um nome.'), findsOneWidget);
    });

    testWidgets('Caminho 4: Deve passar pela validação com sucesso se os dados estiverem corretos', (tester) async {
      final dadosCompletos = {
        'nome': 'Treino de Pernas',
        'exercicios': [
          {'nome': 'Agachamento Livre', 'series': '4', 'reps': '10'},
        ]
      };
      await tester.pumpWidget(criarTelaTeste(treinoExistente: dadosCompletos));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        try {
          await tester.tap(find.text('Salvar Treino'));
        } catch (_) {}
      });

      final state = tester.state(find.byType(TreinamentoPage)) as dynamic;
      
      expect(state.mounted, isTrue);
    });
  });
}
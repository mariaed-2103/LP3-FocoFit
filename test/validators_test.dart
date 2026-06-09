import 'package:flutter_test/flutter_test.dart';
import 'package:fitfoco/validators.dart';

void main() {
  group('Validadores de Caixa Preta (Aula 06) — Login', () {
    test('CT-Login-01: Email vazio deve retornar erro (PE Inválida)', () {
      final resultado = validarLogin('', 'senha123');
      expect(resultado, 'Informe um e-mail.');
    });

    test('CT-Login-02: Senha vazia deve retornar erro (PE Inválida)', () {
      final resultado = validarLogin('usuario@email.com', '');
      expect(resultado, 'Informe a senha.');
    });

    test('CT-Login-03: Dados preenchidos deve retornar null (PE Válida)', () {
      final resultado = validarLogin('usuario@email.com', 'senha123');
      expect(resultado, isNull);
    });
  });

  group('Validadores de Caixa Preta (Aula 06) — Registro', () {
    // ── TESTES DO CAMPO NOME ─────────────────────────────────────────────────
    test('CT-01: Nome com 2 caracteres deve retornar erro (BVA Limite Inf - 1)', () {
      final resultado = validarRegistro('Jo', 'joao@email.com', '123456');
      expect(resultado, 'O nome deve ter pelo menos 3 caracteres.');
    });

    test('CT-02: Nome com exatamente 3 caracteres deve ser válido (BVA Limite Inf)', () {
      final resultado = validarRegistro('Ana', 'ana@email.com', '123456');
      expect(resultado, isNull);
    });

    test('CT-03: Nome com 6 caracteres deve ser válido (PE Válida)', () {
      final resultado = validarRegistro('Carlos', 'carlos@email.com', '123456');
      expect(resultado, isNull);
    });

    // ── TESTES DO CAMPO SENHA ────────────────────────────────────────────────
    test('CT-04: Senha com 5 caracteres deve retornar erro (BVA Limite Inf - 1)', () {
      final resultado = validarRegistro('João', 'joao@email.com', '12345');
      expect(resultado, 'A senha deve ter pelo menos 6 caracteres.');
    });

    test('CT-05: Senha com exatamente 6 caracteres deve ser válida (BVA Limite Inf)', () {
      final resultado = validarRegistro('João', 'joao@email.com', '123456');
      expect(resultado, isNull);
    });

    test('CT-06: Senha com 10 caracteres deve ser válida (BVA Limite Sup)', () {
      final resultado = validarRegistro('João', 'joao@email.com', '1234567890');
      expect(resultado, isNull);
    });
  });

  group('TDD (Aula 08) — Validação de Exercícios (Séries e Repetições)', () {
    test('Deve retornar erro se a quantidade de séries não for um número válido', () {
      // Arrange
      final seriesInvalida = 'abc';
      final repsValida = '12';

      // Act
      final resultado = validarExercicios(seriesInvalida, repsValida);

      // Assert
      expect(resultado, 'As séries devem ser um número válido maior que 0.');
    });

    test('Deve retornar erro se as repetições forem menores ou iguais a zero', () {
      // Arrange
      final seriesValida = '4';
      final repsInvalida = '0';

      // Act
      final resultado = validarExercicios(seriesValida, repsInvalida);

      // Assert
      expect(resultado, 'As repetições devem ser um número válido maior que 0.');
    });

    test('Deve retornar null se ambos os campos forem números inteiros válidos', () {
      // Arrange
      final seriesValida = '3';
      final repsValida = '12';

      // Act
      final resultado = validarExercicios(seriesValida, repsValida);

      // Assert
      expect(resultado, isNull);
    });
  });
  
}
import 'package:flutter_test/flutter_test.dart';
import 'package:fitfoco/validators.dart';

void main() {
  group('validarLogin', () {
    test('email vazio retorna erro', () {
      expect(validarLogin('', 'senha123'), 'Informe um e-mail.');
    });
    test('senha vazia retorna erro', () {
      expect(validarLogin('a@a.com', ''), 'Informe a senha.');
    });
    test('dados corretos retorna null', () {
      expect(validarLogin('a@a.com', 'senha123'), null);
    });
  });

  group('validarRegistro', () {
    test('nome curto retorna erro', () {
      expect(validarRegistro('ab', 'a@a.com', 'senha123'),
        'O nome deve ter pelo menos 3 caracteres.');
    });
    test('senha curta retorna erro', () {
      expect(validarRegistro('João', 'a@a.com', '123'),
        'A senha deve ter pelo menos 6 caracteres.');
    });
  });

   group('regressão — maxLength vs validação', () {
    test('senha com exatamente 6 chars é válida', () {
      expect(validarRegistro('João', 'a@a.com', '123456'), null);
    });
    test('senha com 5 chars é inválida mesmo se maxLength fosse maior', () {
      expect(validarRegistro('João', 'a@a.com', '12345'),
        'A senha deve ter pelo menos 6 caracteres.');
    });
  });

}
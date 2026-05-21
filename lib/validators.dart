String? validarLogin(String email, String senha) {
  if (email.trim().isEmpty) return 'Informe um e-mail.';
  if (senha.isEmpty) return 'Informe a senha.';
  return null;
}

String? validarRegistro(String nome, String email, String senha) {
  if (nome.length < 3) return 'O nome deve ter pelo menos 3 caracteres.';
  if (email.trim().isEmpty) return 'Informe um e-mail.';
  if (senha.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
  return null;
}
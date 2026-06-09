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

String? validarExercicios(String series, String reps) {
  final numSeries = int.tryParse(series);
  if (numSeries == null || numSeries <= 0) {
    return 'As séries devem ser um número válido maior que 0.';
  }

  final numReps = int.tryParse(reps);
  if (numReps == null || numReps <= 0) {
    return 'As repetições devem ser um número válido maior que 0.';
  }

  return null;
}
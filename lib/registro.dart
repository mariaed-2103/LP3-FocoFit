import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final txtNome = TextEditingController();
  final txtEmail = TextEditingController();
  final txtSenha = TextEditingController();
  bool _obscureText = true;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        margin: EdgeInsets.all(60),
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icone_FocoFit.png',
              width: 200,
              height: 200,
            ),
            TextField(
              controller: txtNome,
              maxLength: 20,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                labelText: "Nome de usuário",
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(
                  Icons.person_2_outlined,
                  color: const Color(0xFFCCFF00),
                ),
              ),
            ),
            TextField(
              controller: txtEmail,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                labelText: "E-mail",
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFFCCFF00)),
              ),
            ),
            TextField(
              controller: txtSenha,
              obscureText: _obscureText,
              maxLength: 10,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                labelText: "Senha",
                labelStyle: TextStyle(color: Colors.grey[400]),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFCCFF00),
                  ),
                ),
              ),
            ),

            if (_erro != null)
              Text(
                _erro!,
                style: TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _erro = null);

                // Validação do nome
                if (txtNome.text.length < 3) {
                  setState(() => _erro = 'O nome deve ter pelo menos 3 caracteres.');
                  return;
                }

                // Validação de email
                if (txtEmail.text.trim().isEmpty) {
                  setState(() => _erro = 'Informe um e-mail.');
                  return;
                }

                // Validação da senha
                if (txtSenha.text.length < 6) {
                  setState(() => _erro = 'A senha deve ter pelo menos 6 caracteres.');
                  return;
                }

                // Registro no Firebase
                try {
                  var credential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: txtEmail.text,
                        password: txtSenha.text,
                      );
                  await credential.user?.updateDisplayName(txtNome.text);
                  Navigator.of(context)
                    ..pop()
                    ..pushReplacementNamed("/inicio");
                } on FirebaseAuthException catch (ex) {
                  final mensagem = switch (ex.code) {
                    'email-already-in-use' => 'Este e-mail já está cadastrado.',
                    'invalid-email'        => 'E-mail inválido.',
                    'weak-password'        => 'A senha deve ter pelo menos 6 caracteres.',
                    _                      => ex.message!,
                  };
                  setState(() => _erro = mensagem);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCCFF00),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "REGISTRAR",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "VOLTAR",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

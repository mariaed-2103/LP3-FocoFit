import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
 const LoginPage({super.key});

 @override 
 State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

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
            Image.asset('assets/images/icone_FocoFit.png', width: 200, height: 200),
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
                labelText: "E-mailssss",
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
                    color: const Color(0xFFCCFF00)),
                ),
              ),
            ),
            if (_erro != null)
              Text(
                _erro!,
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _erro = null);

                  // ✅ Validações antes de chamar o Firebase
                  if (txtEmail.text.trim().isEmpty) {
                    setState(() => _erro = 'Informe um e-mail.');
                    return;
                  }

                  if (txtSenha.text.isEmpty) {
                    setState(() => _erro = 'Informe a senha.');
                    return;
                  }
                  
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: txtEmail.text,
                    password: txtSenha.text,
                  );
                  Navigator.pushReplacementNamed(context, "/inicio");
                } on FirebaseAuthException catch (ex) {
                  final mensagem = switch (ex.code) {
                    'user-not-found'     => 'Usuário não encontrado.',
                    'wrong-password'     => 'Senha incorreta.',
                    'invalid-email'      => 'E-mail inválido.',
                    'invalid-credential' => 'E-mail ou senha incorretos.',
                    _                    => ex.message!,
                  };
                  setState(() => _erro = mensagem);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCCFF00),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("ENTRAR", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, "/registro"),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("CRIAR CONTA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
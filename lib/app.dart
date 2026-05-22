import 'package:fitfoco/progresso.dart';
import 'package:fitfoco/treinamento.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'registro.dart';
import 'inicio.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        fontFamily: 'SFPro', 
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFFCCFF00),
          selectionColor: Color(0xFFCCFF00).withOpacity(0.3),
          selectionHandleColor: Color(0xFFCCFF00),
        ),),
      routes: {
        '/login': (context) => LoginPage(),
        '/registro': (context) => RegistroPage(),
        '/inicio': (context) => InicioPage(),
        '/treinamento': (context) => TreinamentoPage(),
        '/progresso': (context) => ProgressoPage(),
      },
      initialRoute: '/login',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressoPage extends StatefulWidget {
  const ProgressoPage({super.key});

  @override
  State<ProgressoPage> createState() => _ProgressoPageState();
}

class _ProgressoPageState extends State<ProgressoPage> {
  int _selectedTab = 1;
  late DateTime _mesAtual;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mesAtual = DateTime(agora.year, agora.month);
  }

  CollectionReference get _concluidosRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('treinos_concluidos');
  }

  Stream<QuerySnapshot> get _streamDoMes {
    final inicio = Timestamp.fromDate(DateTime(_mesAtual.year, _mesAtual.month, 1));
    final fim = Timestamp.fromDate(DateTime(_mesAtual.year, _mesAtual.month + 1, 1));
    return _concluidosRef
        .where('data', isGreaterThanOrEqualTo: inicio)
        .where('data', isLessThan: fim)
        .snapshots();
  }

  String get _nomeMes {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return '${meses[_mesAtual.month - 1]} De ${_mesAtual.year}';
  }

  List<DateTime?> _getDiasDoCalendario() {
    final primeiroDia = DateTime(_mesAtual.year, _mesAtual.month, 1);
    final ultimoDia = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
    final offset = primeiroDia.weekday % 7;
    final dias = <DateTime?>[];
    for (int i = 0; i < offset; i++) dias.add(null);
    for (int i = 1; i <= ultimoDia.day; i++) {
      dias.add(DateTime(_mesAtual.year, _mesAtual.month, i));
    }
    return dias;
  }

  @override
  Widget build(BuildContext context) {
    final dias = _getDiasDoCalendario();
    const accent = Color(0xFFCCFF00);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/inicio'),
        ),
        title: Text('Progresso',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted)
                Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF111111),
        selectedItemColor: accent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedTab,
        onTap: (i) {
          setState(() => _selectedTab = i);
          if (i == 0) Navigator.pushReplacementNamed(context, '/inicio');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Treinos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progresso'),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamDoMes,
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];

          // mapeia dia → quantidade de treinos
          final Map<String, int> treinosPorDia = {};
          for (final doc in docs) {
            final ts = (doc.data() as Map<String, dynamic>)['data'] as Timestamp;
            final data = ts.toDate();
            final chave = '${data.year}-${data.month}-${data.day}';
            treinosPorDia[chave] = (treinosPorDia[chave] ?? 0) + 1;
          }

          final totalMes = docs.length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // navegação de mês
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () => setState(() {
                              _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1);
                            }),
                          ),
                          Text(_nomeMes,
                            style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () => setState(() {
                              _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1);
                            }),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // cabeçalho
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                            .map((d) => SizedBox(
                                  width: 36,
                                  child: Center(
                                    child: Text(d,
                                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ),
                                ))
                            .toList(),
                      ),

                      SizedBox(height: 8),

                      // grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 0,
                          childAspectRatio: 1,
                        ),
                        itemCount: dias.length,
                        itemBuilder: (context, i) {
                          final dia = dias[i];
                          if (dia == null) return SizedBox();

                          final chave = '${dia.year}-${dia.month}-${dia.day}';
                          final quantidade = treinosPorDia[chave] ?? 0;
                          final marcado = quantidade > 0;

                          return Container(
                            margin: EdgeInsets.all(2),
                            decoration: marcado
                                ? BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(10))
                                : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${dia.day}',
                                  style: TextStyle(
                                    color: marcado ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: marcado ? FontWeight.bold : FontWeight.normal,
                                  )),
                                if (quantidade == 1)
                                  Icon(Icons.check, size: 11, color: Colors.black),
                                if (quantidade > 1)
                                  Text('${quantidade}x',
                                    style: const TextStyle(
                                      color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // card total do mês
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: accent, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.check, color: Colors.black, size: 26),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$totalMes',
                            style: TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Treinos Concluídos',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
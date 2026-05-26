import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitfoco/treinamento.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int _selectedTab = 0;

  CollectionReference get _treinosRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('treinos');
  }

  CollectionReference get _concluidosRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('treinos_concluidos');
  }

  // Retorna true se o treino [treinoId] já foi concluído hoje
  bool _concluidoHoje(List<QueryDocumentSnapshot> concluidos, String treinoId) {
    final hoje = DateTime.now();
    return concluidos.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['treinoId'] != treinoId) return false;
      final dt = (data['data'] as Timestamp).toDate();
      return dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day;
    });
  }

  Future<void> _concluirTreino(String treinoId, String nomeTreino) async {
    await _concluidosRef.add({
      'data': Timestamp.now(),
      'treinoId': treinoId,
      'nomeTreino': nomeTreino,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.black),
          SizedBox(width: 10),
          Text('Treino concluído!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: const Color(0xFFCCFF00),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday == 7 ? 6 : hoje.weekday - 1));
    final diasDaSemana = List.generate(7, (i) => inicioSemana.add(Duration(days: i)));
    const nomesDias = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final usuario = FirebaseAuth.instance.currentUser;
    final nome = usuario?.displayName ?? 'Usuário';

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF111111),
        selectedItemColor: Color(0xFFCCFF00),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedTab,
        onTap: (i) {
          setState(() => _selectedTab = i);
          if (i == 1) Navigator.pushReplacementNamed(context, '/progresso');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Treinos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progresso'),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Olá, $nome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted)
                        Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.grey, size: 18),
                    label: const Text(
                      'Sair',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // calendário semanal
              Container(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final dia = diasDaSemana[i];
                    final isHoje =
                        dia.day == hoje.day &&
                        dia.month == hoje.month &&
                        dia.year == hoje.year;

                    return Column(
                      children: [
                        Text(
                          nomesDias[i],
                          style: TextStyle(
                            color: isHoje ? Color(0xFFCCFF00) : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: isHoje
                              ? BoxDecoration(
                                  color: Color(0xFFCCFF00),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Center(
                            child: Text(
                              '${dia.day}',
                              style: TextStyle(
                                color: isHoje ? Colors.black : Colors.white,
                                fontWeight: isHoje ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Meus Treinos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TreinamentoPage()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF333333)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Color(0xFFCCFF00), size: 16),
                          SizedBox(width: 5),
                          Text(
                            'Novo treino',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // stream secundário: concluídos de hoje para marcar o check
                  stream: () {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final hoje = DateTime.now();
                    final inicioDia = Timestamp.fromDate(DateTime(hoje.year, hoje.month, hoje.day));
                    final fimDia   = Timestamp.fromDate(DateTime(hoje.year, hoje.month, hoje.day + 1));
                    return FirebaseFirestore.instance
                        .collection('usuarios').doc(uid).collection('treinos_concluidos')
                        .where('data', isGreaterThanOrEqualTo: inicioDia)
                        .where('data', isLessThan: fimDia)
                        .snapshots();
                  }(),
                  builder: (context, snapConcluidos) {
                    final concluidos = snapConcluidos.data?.docs ?? [];
                    return StreamBuilder<QuerySnapshot>(
                      stream: _treinosRef.orderBy('criadoEm', descending: true).snapshots(),
                      builder: (context, snap) {
                        final docs = snap.data?.docs ?? [];
                        return ListView(
                          children: [
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final nomeTreino = data['nome'] ?? 'Treino';
                              final exercicios = (data['exercicios'] as List?)?.length ?? 0;
                              final feito = _concluidoHoje(concluidos, doc.id);

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TreinamentoPage(
                                      treinoId: doc.id,
                                      treinoExistente: data,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2A2A2A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.flash_on, color: Color(0xFFCCFF00), size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nomeTreino,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              '$exercicios exercício${exercicios == 1 ? '' : 's'}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // botão de check diário
                                      GestureDetector(
                                        onTap: feito ? null : () => _concluirTreino(doc.id, nomeTreino),
                                        child: Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(
                                            color: feito ? const Color(0xFFCCFF00) : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: feito ? const Color(0xFFCCFF00) : Colors.grey,
                                              width: 2,
                                            ),
                                          ),
                                          child: feito
                                              ? const Icon(Icons.check, size: 18, color: Colors.black)
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
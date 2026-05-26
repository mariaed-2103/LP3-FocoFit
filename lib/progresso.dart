import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressoPage extends StatefulWidget {
  const ProgressoPage({super.key});

  @override
  State<ProgressoPage> createState() => _ProgressoPageState();
}

class _ProgressoPageState extends State<ProgressoPage> {
  static const accent = Color(0xFFCCFF00);
  static const bgCard = Color(0xFF1A1A1A);
  static const diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  int _selectedTab = 1;
  late DateTime _mesAtual;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mesAtual = DateTime(agora.year, agora.month);
  }

  // ── Firestore ─────────────────────────────────────────────────────────────

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

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _nomeMes => '${meses[_mesAtual.month - 1]} De ${_mesAtual.year}';

  void _mudarMes(int delta) =>
      setState(() => _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + delta));

  // gera a lista de dias do mês com nulls no início para alinhar ao dia da semana
  List<DateTime?> get _diasDoCalendario {
    final primeiroDia = DateTime(_mesAtual.year, _mesAtual.month, 1);
    final totalDias = DateTime(_mesAtual.year, _mesAtual.month + 1, 0).day;
    final offset = primeiroDia.weekday % 7; // Dom=0, Seg=1 ... Sáb=6

    return [
      for (int i = 0; i < offset; i++) null,
      for (int i = 1; i <= totalDias; i++) DateTime(_mesAtual.year, _mesAtual.month, i),
    ];
  }

  // conta treinos por dia a partir dos documentos do Firestore
  Map<String, int> _contarTreinosPorDia(List<QueryDocumentSnapshot> docs) {
    final mapa = <String, int>{};
    for (final doc in docs) {
      final data = ((doc.data() as Map<String, dynamic>)['data'] as Timestamp).toDate();
      final chave = '${data.year}-${data.month}-${data.day}';
      mapa[chave] = (mapa[chave] ?? 0) + 1;
    }
    return mapa;
  }

  // ── UI reutilizável ───────────────────────────────────────────────────────

  // card com fundo escuro padrão da tela
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/inicio'),
        ),
        title: const Text('Progresso',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted)
                Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF111111),
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
          final treinosPorDia = _contarTreinosPorDia(docs);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card(child: _calendarioCompleto(treinosPorDia)),
                const SizedBox(height: 16),
                _card(child: _cardTotalMes(docs.length)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Calendário ────────────────────────────────────────────────────────────

  Widget _calendarioCompleto(Map<String, int> treinosPorDia) {
    return Column(
      children: [
        _navegacaoMes(),
        const SizedBox(height: 8),
        _cabecalhoSemana(),
        const SizedBox(height: 8),
        _gridDias(treinosPorDia),
      ],
    );
  }

  Widget _navegacaoMes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => _mudarMes(-1),
        ),
        Text(_nomeMes,
          style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: () => _mudarMes(1),
        ),
      ],
    );
  }

  Widget _cabecalhoSemana() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final dia in diasSemana)
          SizedBox(
            width: 36,
            child: Center(
              child: Text(dia,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          ),
      ],
    );
  }

  Widget _gridDias(Map<String, int> treinosPorDia) {
    final dias = _diasDoCalendario;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: dias.length,
      itemBuilder: (context, i) {
        final dia = dias[i];
        if (dia == null) return const SizedBox();

        final chave = '${dia.year}-${dia.month}-${dia.day}';
        final quantidade = treinosPorDia[chave] ?? 0;
        final marcado = quantidade > 0;

        return Container(
          margin: const EdgeInsets.all(2),
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
                const Icon(Icons.check, size: 11, color: Colors.black),
              if (quantidade > 1)
                Text('${quantidade}x',
                  style: const TextStyle(
                    color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  // ── Card total do mês ─────────────────────────────────────────────────────

  Widget _cardTotalMes(int total) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: accent, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.check, color: Colors.black, size: 26),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$total',
              style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Treinos Concluídos',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
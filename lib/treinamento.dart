import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TreinamentoPage extends StatefulWidget {
  final String? treinoId;
  final Map<String, dynamic>? treinoExistente;

  const TreinamentoPage({super.key, this.treinoId, this.treinoExistente});

  @override
  State<TreinamentoPage> createState() => _TreinamentoPageState();
}

class _TreinamentoPageState extends State<TreinamentoPage> {
  static const accent = Color(0xFFCCFF00);
  static const bgCard = Color(0xFF1A1A1A);

  final _nomeTreinoController = TextEditingController();
  final List<Map<String, dynamic>> _exercicios = [];
  bool _modoEdicao = false;
  bool _modoReordenar = false;
  bool _carregando = false;
  String? _docId;

  @override
  void initState() {
    super.initState();
    _docId = widget.treinoId;
    if (widget.treinoExistente != null) {
      _nomeTreinoController.text = widget.treinoExistente!['nome'] ?? '';
      for (final ex in (widget.treinoExistente!['exercicios'] as List? ?? [])) {
        _exercicios.add({
          'nome': TextEditingController(text: ex['nome'] ?? ''),
          'series': TextEditingController(text: ex['series'] ?? '3'),
          'reps': TextEditingController(text: ex['reps'] ?? '12'),
          'concluido': false,
        });
      }
    }
  }

  // ── Firestore ─────────────────────────────────────────────────────────────

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

  // ── Exercícios ────────────────────────────────────────────────────────────

  void _adicionarExercicio() => setState(() {
    _exercicios.add({
      'nome': TextEditingController(),
      'series': TextEditingController(text: '3'),
      'reps': TextEditingController(text: '12'),
      'concluido': false,
    });
  });

  Future<void> _removerExercicio(int i) async {
    setState(() => _exercicios.removeAt(i));
    if (_docId != null) await _sincronizarFirestore(silencioso: true);
  }

  void _toggleExercicio(int i) => setState(
    () => _exercicios[i]['concluido'] = !_exercicios[i]['concluido'],
  );

  Future<void> _reordenar(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _exercicios.removeAt(oldIndex);
      _exercicios.insert(newIndex, item);
    });
    if (_docId != null) await _sincronizarFirestore(silencioso: true);
  }

  // ── Edição individual ─────────────────────────────────────────────────────

  void _editarExercicio(int index) {
    final ex = _exercicios[index];
    final nomeCtrl = TextEditingController(
      text: (ex['nome'] as TextEditingController).text,
    );
    final seriesCtrl = TextEditingController(
      text: (ex['series'] as TextEditingController).text,
    );
    final repsCtrl = TextEditingController(
      text: (ex['reps'] as TextEditingController).text,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        title: const Text('Editar Exercício',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nome do exercício',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: seriesCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Séries',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true, fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Repetições',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true, fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) {
                _aviso('O exercício precisa de um nome.');
                return;
              }
              (ex['nome'] as TextEditingController).text = nomeCtrl.text.trim();
              (ex['series'] as TextEditingController).text = seriesCtrl.text.trim();
              (ex['reps'] as TextEditingController).text = repsCtrl.text.trim();
              setState(() {});
              Navigator.pop(ctx);
              if (_docId != null) await _sincronizarFirestore(silencioso: true);
            },
            child: const Text('Salvar',
              style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Sincronizar exercícios no Firestore ───────────────────────────────────

  Future<void> _sincronizarFirestore({bool silencioso = false}) async {
    if (_docId == null) return;
    try {
      await _treinosRef.doc(_docId).update({'exercicios': _exerciciosData});
    } on FirebaseException catch (e) {
      if (!silencioso) _aviso('Erro ao sincronizar: ${e.message}');
    } catch (_) {
      if (!silencioso) _aviso('Erro inesperado ao sincronizar.');
    }
  }

  // ── Validação geral ───────────────────────────────────────────────────────

  bool _validar() {
    if (_nomeTreinoController.text.trim().isEmpty) {
      _aviso('Dê um nome ao treino antes de continuar.'); return false;
    }
    if (_exercicios.isEmpty) {
      _aviso('Adicione ao menos um exercício antes de continuar.'); return false;
    }
    for (int i = 0; i < _exercicios.length; i++) {
      if ((_exercicios[i]['nome'] as TextEditingController).text.trim().isEmpty) {
        _aviso('O exercício ${i + 1} precisa de um nome.'); return false;
      }
    }
    return true;
  }

  List<Map<String, String>> get _exerciciosData => _exercicios.map((e) => {
    'nome': (e['nome'] as TextEditingController).text.trim(),
    'series': (e['series'] as TextEditingController).text.trim(),
    'reps': (e['reps'] as TextEditingController).text.trim(),
  }).toList();

  // ── Salvar ────────────────────────────────────────────────────────────────

  Future<bool> _salvar({bool silencioso = false}) async {
    if (!_validar()) return false;
    setState(() => _carregando = true);

    try {
      final dados = {
        'nome': _nomeTreinoController.text.trim(),
        'exercicios': _exerciciosData,
        'criadoEm': Timestamp.now(),
      };

      if (_docId != null) {
        await _treinosRef.doc(_docId).update(dados);
      } else {
        final ref = await _treinosRef.add(dados);
        _docId = ref.id;
      }

      if (!silencioso) {
        _sucesso('Treino salvo com sucesso!');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, '/inicio');
      }
      return true;
    } on FirebaseException catch (e) {
      _aviso('Erro ao salvar: ${e.message}');
      return false;
    } catch (_) {
      _aviso('Erro inesperado ao salvar o treino.');
      return false;
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Concluir ──────────────────────────────────────────────────────────────

  Future<void> _concluir() async {
    final salvo = await _salvar(silencioso: true);
    if (!salvo) return;

    setState(() => _carregando = true);
    try {
      await _concluidosRef.add({
        'data': Timestamp.now(),
        'treinoId': _docId,
        'nomeTreino': _nomeTreinoController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: const [
          Icon(Icons.check_circle, color: Colors.black),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Treino concluído! Registrado no seu progresso.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          )),
        ]),
        backgroundColor: accent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pushReplacementNamed(context, '/inicio');
    } on FirebaseException catch (e) {
      _aviso('Erro ao concluir: ${e.message}');
    } catch (_) {
      _aviso('Erro inesperado ao concluir o treino.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Deletar treino ────────────────────────────────────────────────────────

  Future<void> _deletarTreino() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        title: const Text('Excluir treino',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Tem certeza que deseja excluir este treino? Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      if (_docId != null) await _treinosRef.doc(_docId).delete();
      if (mounted) Navigator.pushReplacementNamed(context, '/inicio');
    } on FirebaseException catch (e) {
      _aviso('Erro ao excluir: ${e.message}');
    } catch (_) {
      _aviso('Erro inesperado ao excluir o treino.');
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  void _aviso(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    backgroundColor:  accent,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 1),
  ));

  void _sucesso(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.black)),
    backgroundColor: accent,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 1),
  ));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_modoReordenar) {
              setState(() => _modoReordenar = false);
            } else if (_modoEdicao) {
              setState(() => _modoEdicao = false);
            } else {
              Navigator.pushReplacementNamed(context, '/inicio');
            }
          },
        ),
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _nomeTreinoController,
            style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Nome do treino',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF2A2A2A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_docId != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: _carregando ? null : _deletarTreino,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Excluir treino',
                  ),
                  Container(width: 1, height: 20, color: Color(0xFF2A2A2A)),
                ],
                if (_exercicios.length > 1) ...[
                  IconButton(
                    icon: Icon(
                      Icons.swap_vert,
                      color: _modoReordenar ? accent : Colors.white,
                      size: 20,
                    ),
                    onPressed: () => setState(() {
                      _modoReordenar = !_modoReordenar;
                      if (_modoReordenar) _modoEdicao = false;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Reordenar exercícios',
                  ),
                  Container(width: 1, height: 20, color: Color(0xFF2A2A2A)),
                ],
                TextButton(
                  onPressed: () {
                    if (_exercicios.isEmpty) {
                      _aviso('Adicione ao menos um exercício para editar.');
                      return;
                    }
                    setState(() {
                      _modoEdicao = !_modoEdicao;
                      if (_modoEdicao) _modoReordenar = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _modoEdicao ? 'Concluir' : 'Editar',
                    style: TextStyle(
                      color: _modoEdicao ? accent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _modoReordenar
                ? _listaReordenavel()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._exercicios.asMap().entries.map((e) => _modoEdicao
                          ? _cardEdicao(e.key, e.value)
                          : _cardVisualizacao(e.key, e.value)),

                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _adicionarExercicio,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF444444),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                          backgroundColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.grey, size: 18),
                            SizedBox(width: 8),
                            Text('Adicionar exercício',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: _carregando ? null : () => _salvar(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF333333)),
                                backgroundColor: bgCard,
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Salvar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                )),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: _carregando ? null : _concluir,
                              icon: _carregando
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.check, color: Colors.black, size: 18),
                              label: const Text('Concluir',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                )),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Lista reordenável ──────────────────────────────────────

  Widget _listaReordenavel() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      onReorder: _reordenar,
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: child,
      ),
      itemCount: _exercicios.length,
      itemBuilder: (context, i) {
        final ex = _exercicios[i];
        final nome = (ex['nome'] as TextEditingController).text;
        final series = (ex['series'] as TextEditingController).text;
        final reps = (ex['reps'] as TextEditingController).text;

        return Container(
          key: ValueKey(i),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgCard, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.drag_handle, color: Colors.grey),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isEmpty ? 'Exercício ${i + 1}' : nome,
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text('$series séries × $reps reps',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardVisualizacao(int index, Map<String, dynamic> ex) {
    final nome = (ex['nome'] as TextEditingController).text;
    final series = (ex['series'] as TextEditingController).text;
    final reps = (ex['reps'] as TextEditingController).text;
    final concluido = ex['concluido'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleExercicio(index),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: concluido ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: concluido ? accent : Colors.grey, width: 2),
              ),
              child: concluido
                  ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome.isEmpty ? 'Exercício ${index + 1}' : nome,
                  style: TextStyle(
                    color: concluido ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15,
                    decoration: concluido ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$series séries × $reps reps',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'editar') _editarExercicio(index);
              if (value == 'excluir') _removerExercicio(index);
            },
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Editar', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Text('Excluir', style: TextStyle(color: Colors.red, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card edição geral ──────────────────────────────────────

  Widget _cardEdicao(int index, Map<String, dynamic> ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ex['nome'] as TextEditingController,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Nome do exercício',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true, fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Séries', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ex['series'] as TextEditingController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Repetições', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ex['reps'] as TextEditingController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _removerExercicio(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Excluir Exercício',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
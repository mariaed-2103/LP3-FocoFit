import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Exercicio {
  final TextEditingController nome;
  final TextEditingController series;
  final TextEditingController reps;
  bool concluido;

  Exercicio({String nome = '', String series = '3', String reps = '12'})
      : nome = TextEditingController(text: nome),
        series = TextEditingController(text: series),
        reps = TextEditingController(text: reps),
        concluido = false;

  Map<String, String> toMap() => {
    'nome': nome.text.trim(),
    'series': series.text.trim(),
    'reps': reps.text.trim(),
  };

  factory Exercicio.fromMap(Map<String, dynamic> map) => Exercicio(
    nome: map['nome'] ?? '',
    series: map['series'] ?? '3',
    reps: map['reps'] ?? '12',
  );

  void dispose() {
    nome.dispose();
    series.dispose();
    reps.dispose();
  }
}

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

  final _nomeTreino = TextEditingController();
  final List<Exercicio> _exercicios = [];
  final Set<int> _novos = {};
  bool _modoEdicao = false;
  bool _modoReordenar = false;
  bool _carregando = false;
  String? _docId;

  bool get _emEdicao => _modoEdicao || _novos.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _docId = widget.treinoId;
    if (widget.treinoExistente != null) {
      _nomeTreino.text = widget.treinoExistente!['nome'] ?? '';
      for (final ex in (widget.treinoExistente!['exercicios'] as List? ?? [])) {
        _exercicios.add(Exercicio.fromMap(ex));
      }
    } else {
      _modoEdicao = true;
    }
  }

  @override
  void dispose() {
    _nomeTreino.dispose();
    for (final ex in _exercicios) ex.dispose();
    super.dispose();
  }

  // ── Firestore ─────────────────────────────────────────────────────────────

  CollectionReference get _treinosRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('treinos');
  }

  // ── Exercícios ────────────────────────────────────────────────────────────

  void _adicionar() => setState(() {
    _novos.add(_exercicios.length);
    _exercicios.add(Exercicio());
  });

  Future<void> _remover(int i) async {
    setState(() {
      _exercicios.removeAt(i);
      // remove o índice e reajusta os que eram maiores que i
      _novos.removeWhere((idx) => idx == i);
      final ajustados = _novos.map((idx) => idx > i ? idx - 1 : idx).toSet();
      _novos..clear()..addAll(ajustados);
    });
    if (_docId != null) await _sincronizar();
  }

  void _toggle(int i) =>
      setState(() => _exercicios[i].concluido = !_exercicios[i].concluido);

  Future<void> _reordenar(int de, int para) async {
    if (para > de) para--;
    setState(() => _exercicios.insert(para, _exercicios.removeAt(de)));
    if (_docId != null) await _sincronizar();
  }

  // ── Sincronizar ───────────────────────────────────────────────────────────

  Future<void> _sincronizar() async {
    try {
      await _treinosRef.doc(_docId).update({
        'exercicios': _exercicios.map((e) => e.toMap()).toList(),
      });
    } on FirebaseException catch (e) {
      _snackbar('Erro ao sincronizar: ${e.message}');
    } catch (_) {
      _snackbar('Erro inesperado ao sincronizar.');
    }
  }

  // ── Validação ─────────────────────────────────────────────────────────────

  bool _validar() {
    if (_nomeTreino.text.trim().isEmpty) {
      _snackbar('Dê um nome ao treino antes de continuar.'); return false;
    }
    for (int i = 0; i < _exercicios.length; i++) {
      if (_exercicios[i].nome.text.trim().isEmpty) {
        _snackbar('O exercício ${i + 1} precisa de um nome.'); return false;
      }
    }
    return true;
  }

  // ── Salvar ────────────────────────────────────────────────────────────────

  Future<void> _salvar() async {
    if (!_validar()) return;

    if (_exercicios.isEmpty) {
      _snackbar('Treino salvo! Lembre-se de adicionar exercícios depois.',
          duracao: 3);
    }

    setState(() => _carregando = true);
    try {
      final dados = {
        'nome': _nomeTreino.text.trim(),
        'exercicios': _exercicios.map((e) => e.toMap()).toList(),
        'criadoEm': Timestamp.now(),
      };

      if (_docId != null) {
        await _treinosRef.doc(_docId).update(dados);
      } else {
        _docId = (await _treinosRef.add(dados)).id;
      }

      if (_exercicios.isNotEmpty) _snackbar('Treino salvo com sucesso!');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pushReplacementNamed(context, '/inicio');
    } on FirebaseException catch (e) {
      _snackbar('Erro ao salvar: ${e.message}');
    } catch (_) {
      _snackbar('Erro inesperado ao salvar o treino.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Deletar treino ────────────────────────────────────────────────────────

  Future<void> _deletar() async {
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
      _snackbar('Erro ao excluir: ${e.message}');
    } catch (_) {
      _snackbar('Erro inesperado ao excluir o treino.');
    }
  }

  // ── Edição individual via diálogo ─────────────────────────────────────────

  void _editarExercicio(int index) {
    final ex = _exercicios[index];
    final nomeCtrl = TextEditingController(text: ex.nome.text);
    final seriesCtrl = TextEditingController(text: ex.series.text);
    final repsCtrl = TextEditingController(text: ex.reps.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        title: const Text('Editar Exercício',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campoTexto(nomeCtrl, 'Nome do exercício'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _campoTexto(seriesCtrl, 'Séries', numerico: true)),
              const SizedBox(width: 12),
              Expanded(child: _campoTexto(repsCtrl, 'Repetições', numerico: true)),
            ]),
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
                _snackbar('O exercício precisa de um nome.'); return;
              }
              ex.nome.text = nomeCtrl.text.trim();
              ex.series.text = seriesCtrl.text.trim();
              ex.reps.text = repsCtrl.text.trim();
              setState(() {});
              Navigator.pop(ctx);
              if (_docId != null) await _sincronizar();
            },
            child: const Text('Salvar',
              style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Snackbar unificado ────────────────────────────────────────────────────
  // substitui _aviso e _sucesso que faziam a mesma coisa

  void _snackbar(String msg, {int duracao = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(
        color: Colors.black, fontWeight: FontWeight.bold)),
      backgroundColor: accent,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: duracao),
    ));
  }

  // ── Campo de texto reutilizável ───────────────────────────────────────────

  Widget _campoTexto(TextEditingController ctrl, String label,
      {bool numerico = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numerico ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
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
          onPressed: () {
            if (_modoReordenar) {
              setState(() => _modoReordenar = false);
            } else if (_emEdicao) {
              setState(() { _modoEdicao = false; _novos.clear(); });
            } else {
              Navigator.pushReplacementNamed(context, '/inicio');
            }
          },
        ),
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(children: [
              Icon(Icons.flash_on, color: accent, size: 12),
              SizedBox(width: 4),
              Text('TREINO', style: TextStyle(
                color: accent, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 2),
            TextField(
              controller: _nomeTreino,
              style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Nome do treino',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 20,
                  fontWeight: FontWeight.bold),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        actions: [
          if (_docId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _carregando ? null : _deletar,
            ),
          if (_exercicios.length > 1)
            IconButton(
              icon: Icon(Icons.swap_vert,
                color: _modoReordenar ? accent : Colors.white),
              onPressed: () => setState(() {
                _modoReordenar = !_modoReordenar;
                if (_modoReordenar) _modoEdicao = false;
              }),
            ),
          TextButton(
            onPressed: () {
              if (_exercicios.isEmpty) {
                _snackbar('Adicione ao menos um exercício para editar.');
                return;
              }
              setState(() {
                if (_novos.isNotEmpty && !_modoEdicao) {
                  _novos.clear();
                } else {
                  _modoEdicao = !_modoEdicao;
                  if (!_modoEdicao) _novos.clear();
                  if (_modoEdicao) _modoReordenar = false;
                }
              });
            },
            child: Text(
              _emEdicao ? 'Concluir edição' : 'Editar',
              style: TextStyle(
                color: _emEdicao ? accent : Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                      for (int i = 0; i < _exercicios.length; i++)
                        (_modoEdicao || _novos.contains(i))
                            ? _cardEdicao(i)
                            : _cardVisualizacao(i),
                      const SizedBox(height: 8),
                      _botaoOutline(
                        onPressed: _adicionar,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Adicionar Exercício',
                              style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w600, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _botaoOutline(
                        onPressed: _carregando ? null : _salvar,
                        child: _carregando
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                            : const Text('Salvar Treino',
                                style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Botão outline reutilizável ────────────────────────────────────────────

  Widget _botaoOutline({required Widget child, VoidCallback? onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF333333)),
        backgroundColor: bgCard,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: child,
    );
  }

  // ── Lista reordenável ─────────────────────────────────────────────────────

  Widget _listaReordenavel() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      onReorder: _reordenar,
      proxyDecorator: (child, index, animation) =>
          Material(color: Colors.transparent, child: child),
      itemCount: _exercicios.length,
      itemBuilder: (context, i) {
        final ex = _exercicios[i];
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
                      ex.nome.text.isEmpty ? 'Exercício ${i + 1}' : ex.nome.text,
                      style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text('${ex.series.text} séries × ${ex.reps.text} reps',
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

  // ── Card visualização ─────────────────────────────────────────────────────

  Widget _cardVisualizacao(int i) {
    final ex = _exercicios[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggle(i),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: ex.concluido ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ex.concluido ? accent : Colors.grey, width: 2),
              ),
              child: ex.concluido
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.nome.text.isEmpty ? 'Exercício ${i + 1}' : ex.nome.text,
                  style: TextStyle(
                    color: ex.concluido ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15,
                    decoration: ex.concluido ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text('${ex.series.text} séries × ${ex.reps.text} reps',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            onPressed: () => _editarExercicio(i),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _remover(i),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Card edição geral ─────────────────────────────────────────────────────

  Widget _cardEdicao(int i) {
    final ex = _exercicios[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _campoTexto(ex.nome, 'Nome do exercício'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _campoTexto(ex.series, 'Séries', numerico: true)),
            const SizedBox(width: 12),
            Expanded(child: _campoTexto(ex.reps, 'Repetições', numerico: true)),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _remover(i),
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
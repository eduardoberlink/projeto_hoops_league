// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:front_end/app_colors.dart';
import 'package:front_end/services/api_services.dart';
import 'package:front_end/components/profile_page.dart';
import 'package:front_end/components/buscar_partida_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuscarJogadorPage extends StatefulWidget {
  final bool modoConvite;
  final int? compId; // ← ID da partida quando em modo convite

  const BuscarJogadorPage({
    super.key,
    this.modoConvite = false,
    this.compId,
  });

  @override
  State<BuscarJogadorPage> createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarJogadorPage> {
  final TextEditingController searchController = TextEditingController();

  static const preto   = Color(0xFF1A1413);
  static const laranja = Color(0xFFED5223);
  static const branco  = Color(0xFFFDFDFD);

  List<dynamic> filtrados = [];
  List<dynamic> recentes  = [];
  Set<int> convidados = {}; 
  bool loading = false;
  Map<String, dynamic>? usuarioLogado;


  static const _prefKey = 'recentes_jogadores';

  Future<void> _carregarRecentes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      setState(() => recentes = List<dynamic>.from(jsonDecode(raw)));
    }
  }

  Future<void> _salvarRecentes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(recentes.take(10).toList()));
  }

  void _adicionarRecente(dynamic jogador) {
    recentes.removeWhere((j) => j['id'] == jogador['id']);
    recentes.insert(0, jogador);
    _salvarRecentes();
  }

  void _removerRecente(dynamic jogador) {
    setState(() => recentes.removeWhere((j) => j['id'] == jogador['id']));
    _salvarRecentes();
  }


  @override
  void initState() {
    super.initState();
    _carregarRecentes();
    _carregarUsuarioLogado();
    if (widget.modoConvite && widget.compId != null) {
      _carregarJaConvidados();
    }
  }

  Future<void> _carregarUsuarioLogado() async {
    final data = await ApiService.getProfile();
    setState(() => usuarioLogado = data);
  }

 
  Future<void> _carregarJaConvidados() async {
    final response = await ApiService.get("/comp/${widget.compId}/jogadores");
    if (response != null) {
      setState(() {
        convidados = Set<int>.from(
          (response as List).map((j) => j['id'] as int),
        );
      });
    }
  }

  void buscar(String texto) async {
    if (texto.isEmpty) {
      setState(() => filtrados = []);
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.get("/auth/buscar-usuario/$texto");

    setState(() {
      final todos = List<dynamic>.from(response ?? []);
      filtrados = todos
          .where((j) => j['id'] != usuarioLogado?['id'])
          .toList();
      for (var jogador in filtrados) {
        _adicionarRecente(jogador);
      }
      loading = false;
    });
  }


  Future<void> _convidar(dynamic jogador) async {
    final int jogadorId = jogador['id'];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: preto,
        title: const Text("Convidar jogador",
            style: TextStyle(color: laranja)),
        content: Text(
          "Adicionar ${jogador['user']} à partida?",
          style: const TextStyle(color: branco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Convidar", style: TextStyle(color: laranja)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final response = await ApiService.post(
      "/comp/${widget.compId}/convidar/$jogadorId",
      {},
    );

    if (response.statusCode == 200) {
      setState(() => convidados.add(jogadorId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${jogador['user']} adicionado à partida!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final body = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body['detail'] ?? "Erro ao convidar jogador"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget cardJogador(dynamic jogador, {bool isRecente = false}) {
    final int jogadorId = jogador['id'];
    final bool jaConvidado = convidados.contains(jogadorId);

    Widget trailingWidget;

    if (widget.modoConvite) {

      trailingWidget = jaConvidado
          ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
          : IconButton(
              icon: const Icon(Icons.person_add, color: laranja),
              onPressed: () => _convidar(jogador),
            );
    } else if (isRecente) {
      // Modo normal + recente: botão fechar
      trailingWidget = IconButton(
        icon: const Icon(Icons.close, size: 18, color: preto),
        onPressed: () => _removerRecente(jogador),
      );
    } else {
      // Modo normal: OVR
      trailingWidget = Text(
        "OVR: ${jogador["overall"]}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: branco,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (widget.modoConvite && jaConvidado) ? Colors.green : laranja,
          child: const Icon(Icons.person, color: branco),
        ),
        title: Text(
          jogador["user"],
          style: const TextStyle(color: laranja, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${jogador["nome"]}  •  OVR: ${jogador["overall"]}",
          style: const TextStyle(color: preto),
        ),
        trailing: trailingWidget,
        onTap: () {
          if (widget.modoConvite) {
            if (!jaConvidado) _convidar(jogador);
          } else {
            if (!isRecente) _adicionarRecente(jogador);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }


  Widget _secaoRecentes() {
    if (recentes.isEmpty) {
      return const Center(
        child: Text(
          "Suas buscas recentes aparecerão aqui",
          style: TextStyle(color: branco),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Buscas recentes",
              style: TextStyle(
                color: branco,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => recentes.clear());
                _salvarRecentes();
              },
              child: const Text(
                "Limpar tudo",
                style: TextStyle(color: laranja, fontSize: 12),
              ),
            ),
          ],
        ),
        ...recentes
            .take(10)
            .map((j) => cardJogador(j, isRecente: true))
            .toList(),
      ],
    );
  }
  

  @override
  Widget build(BuildContext context) {
    final buscando = searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: preto,
      appBar: AppBar(
        title: Text(
            widget.modoConvite ? "Convidar Jogadores" : "Buscar Jogadores"),
        backgroundColor: laranja,
        actions: widget.modoConvite && convidados.isNotEmpty
            ? [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${convidados.length} adicionado(s)",
                        style: const TextStyle(
                            color: branco, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: buscar,
              decoration: InputDecoration(
                filled: true,
                fillColor: branco,
                hintText: widget.modoConvite
                    ? "Buscar jogador para convidar..."
                    : "Buscar jogador...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: buscando
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() => filtrados = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            Expanded(
              child: buscando
                  ? filtrados.isEmpty && !loading
                      ? const Center(
                          child: Text(
                            "Nenhum jogador encontrado",
                            style: TextStyle(color: branco),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (_, i) => cardJogador(filtrados[i]),
                        )
                  : ListView(children: [_secaoRecentes()]),
            ),
          ],
        ),
      ),
      // Sem bottom nav no modo convite
      bottomNavigationBar: widget.modoConvite
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: laranja,
              selectedItemColor: preto,
              unselectedItemColor: AppColors.branco,
              currentIndex: 2,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: (index) {
                if (index == 1) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => BuscarPartidaPage()));
                }
                if (index == 3) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()));
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home, size: 35,), label: ''),
                BottomNavigationBarItem(
                    icon: Icon(Icons.sports_basketball, size: 35,), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.search, size: 35,), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.person, size: 35,), label: ''),
              ],
            ),
    );
  }
}
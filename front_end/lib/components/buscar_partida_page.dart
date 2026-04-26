// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:front_end/services/api_services.dart';
import 'package:front_end/components/profile_page.dart';
import 'package:front_end/components/buscar_jogador_page.dart';
import 'package:front_end/components/cadastro_partida_page.dart';
import 'package:front_end/components/edit_partida_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuscarPartidaPage extends StatefulWidget {
  const BuscarPartidaPage({super.key});

  @override
  State<BuscarPartidaPage> createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarPartidaPage> {
  final TextEditingController searchController = TextEditingController();

  static const preto   = Color(0xFF1A1413);
  static const laranja = Color(0xFFED5223);
  static const branco  = Color(0xFFFDFDFD);

  List<dynamic> partidas  = [];
  List<dynamic> filtrados = [];
  List<dynamic> recentes  = [];
  bool loading = true;
  Map<String, dynamic>? usuarioLogado;

  // ── Persistência ──────────────────────────────────────────
  static const _prefKey = 'recentes_partidas';

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

  void _adicionarRecente(dynamic partida) {
    recentes.removeWhere((p) => p['id'] == partida['id']);
    recentes.insert(0, partida);
    _salvarRecentes();
  }

  void _removerRecente(dynamic partida) {
    setState(() => recentes.removeWhere((p) => p['id'] == partida['id']));
    _salvarRecentes();
  }
  // ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    carregarPartidas();
    carregarUsuario();
    _carregarRecentes();
  }

  void carregarUsuario() async {
    final data = await ApiService.getProfile();
    setState(() => usuarioLogado = data);
  }

  void carregarPartidas() async {
    setState(() => loading = true);
    final response = await ApiService.get("/comp/");
    setState(() {
      partidas = response ?? [];
      loading = false;
    });
  }

  void buscar(String texto) {
    if (texto.isEmpty) {
      setState(() => filtrados = []);
      return;
    }

    final resultado = partidas.where((p) {
      return (p["local"] ?? "").toLowerCase().contains(texto.toLowerCase());
    }).toList();

    setState(() {
      filtrados = resultado;
      for (var partida in filtrados) {
        _adicionarRecente(partida);
      }
    });
  }

  void excluir(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: preto,
        title: const Text("Deletar partida", style: TextStyle(color: laranja)),
        content: const Text(
          "Tem certeza que deseja deletar esta partida?",
          style: TextStyle(color: branco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Deletar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final sucesso = await ApiService.delete("/comp/deletar/$id");
    if (sucesso) {
      setState(() => recentes.removeWhere((p) => p['id'] == id));
      _salvarRecentes();
      carregarPartidas();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Partida deletada")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Erro ao deletar partida")));
    }
  }

  
  Future<void> convidarJogadores(int compId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuscarJogadorPage(
          modoConvite: true,
          compId: compId, 
        ),
      ),
    );
  }
  

  Widget cardPartida(dynamic partida, {bool isRecente = false}) {
    final int id          = partida["id"];
    final String local    = partida["local"] ?? "Sem local";
    final String status   = partida["status"] ?? "";
    final String tipo     = partida["tipo"] ?? "";
    final String visib    = partida["visibilidade"] ?? "";
    final bool isDono     = usuarioLogado != null &&
        partida["fk_Jogador_id"] == usuarioLogado!["id"];

    return GestureDetector(
      onTap: () {
        _adicionarRecente(partida);
        _mostrarOpcoesPartida(partida, isDono);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: branco,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: laranja,
                child: Icon(Icons.sports_basketball, color: branco),
              ),
              title: Text(
                local,
                style: const TextStyle(
                    color: laranja, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "$tipo • $visib",
                style: const TextStyle(color: preto),
              ),
              trailing: isRecente
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: preto),
                      onPressed: () => _removerRecente(partida),
                    )
                  : isDono
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: laranja),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditPartidaPage(compId: id),
                                  ),
                                );
                                carregarPartidas();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () => excluir(id),
                            ),
                          ],
                        )
                      : null,
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color.fromARGB(51, 0, 0, 0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _corStatus(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                          color: branco, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Botão convidar só aparece se for dono
                  if (isDono)
                    TextButton.icon(
                      onPressed: () => convidarJogadores(id),
                      icon: const Icon(Icons.person_add, color: laranja),
                      label: const Text(
                        "Convidar",
                        style: TextStyle(color: laranja),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcoesPartida(dynamic partida, bool isDono) {
    showModalBottomSheet(
      context: context,
      backgroundColor: preto,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              partida["local"] ?? "Partida",
              style: const TextStyle(
                  color: laranja,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Status: ${partida["status"]} • Tipo: ${partida["tipo"]}",
              style: const TextStyle(color: branco),
            ),
            const Divider(color: Colors.grey),
            if (isDono) ...[
              ListTile(
                leading: const Icon(Icons.person_add, color: laranja),
                title: const Text("Convidar jogadores",
                    style: TextStyle(color: branco)),
                onTap: () {
                  Navigator.pop(context);
                  convidarJogadores(partida["id"]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: laranja),
                title: const Text("Editar partida",
                    style: TextStyle(color: branco)),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditPartidaPage(compId: partida["id"]),
                    ),
                  );
                  carregarPartidas();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Deletar partida",
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  excluir(partida["id"]);
                },
              ),
            ] else ...[
              // Não-dono só pode ver detalhes
              ListTile(
                leading: const Icon(Icons.info_outline, color: laranja),
                title: const Text("Detalhes da partida",
                    style: TextStyle(color: branco)),
                subtitle: Text(
                  "Qtd. máx: ${partida["qtd_max_jogadores"]} jogadores",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _corStatus(String status) {
    switch (status) {
      case "em_aberto":   return Colors.blue;
      case "confirmado":  return Colors.green;
      case "cancelado":   return Colors.red;
      case "encerrado":   return Colors.grey;
      default:            return Colors.orange;
    }
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
              "Partidas recentes",
              style: TextStyle(
                  color: branco, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextButton(
              onPressed: () {
                setState(() => recentes.clear());
                _salvarRecentes();
              },
              child: const Text("Limpar tudo",
                  style: TextStyle(color: laranja, fontSize: 12)),
            ),
          ],
        ),
        ...recentes
            .take(10)
            .map((p) => cardPartida(p, isRecente: true))
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
        title: const Text("Buscar Partidas"),
        backgroundColor: laranja,
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
                hintText: "Buscar por local...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: buscando
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          buscar('');
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
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (!buscando)
              Expanded(
                child: ListView(children: [_secaoRecentes()]),
              )
            else if (filtrados.isEmpty)
              const Expanded(
                child: Center(
                  child: Text("Nenhuma partida encontrada",
                      style: TextStyle(color: branco)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) =>
                      cardPartida(filtrados[index]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: laranja,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroPartidaPage()),
          );
          carregarPartidas();
        },
        child: const Icon(Icons.add, color: branco),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: laranja,
        selectedItemColor: preto,
        unselectedItemColor: branco,
        currentIndex: 1,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => BuscarJogadorPage()));
          }
          if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 35,), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_basketball, size: 35), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 35), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 35), label: ''),
        ],
      ),
    );
  }
}
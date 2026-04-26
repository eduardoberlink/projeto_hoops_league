// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:front_end/components/buscar_jogador_page.dart';
import 'package:front_end/modules/models/jogador.dart';
import 'package:front_end/services/api_services.dart';
import 'dart:convert';

class CadastroPartidaPage extends StatefulWidget {
  const CadastroPartidaPage({super.key});

  @override
  State<CadastroPartidaPage> createState() => _CadastroPartidaPageState();
}

class _CadastroPartidaPageState extends State<CadastroPartidaPage> {
  static const preto = Color(0xFF1A1413);
  static const laranja = Color(0xFFED5223);
  static const branco = Color(0xFFFDFDFD);

  final localController = TextEditingController();
  final horaController = TextEditingController();

  DateTime? dataSelecionada;
  List<Jogador> jogadoresSelecionados = [];
  bool loading = false;

  String visibilidade = "publico";
  int qtdTimes = 2;
  String tipo = "partida";
  int qtdMaxJogadores = 10;

  final List<Map<String, String>> visibilidades = const [
    {"value": "publico", "label": "Público"},
    {"value": "privado", "label": "Privado"},
  ];

  final List<Map<String, String>> tipos = const [
    {"value": "partida", "label": "Partida"},
    {"value": "torneio", "label": "Torneio"},
  ];

  Future<void> selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => dataSelecionada = picked);
  }

  Future<void> selecionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        horaController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> irParaBusca() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuscarJogadorPage(modoConvite: true)),
    );
    if (resultado != null && resultado is List<Jogador>) {
      setState(() => jogadoresSelecionados = resultado);
    }
  }

  Future<void> criarPartida() async {
    if (localController.text.trim().isEmpty ||
        dataSelecionada == null ||
        horaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final dataFormatada = DateFormat('yyyy-MM-dd').format(dataSelecionada!);

      final compResponse = await ApiService.post("/comp/criar", {
        "local": localController.text.trim(),
        "status": "em_aberto",
        "visibilidade": visibilidade,
        "qtd_times": qtdTimes,
        "tipo": tipo,
        "qtd_max_jogadores": qtdMaxJogadores,
        "data_partida": dataFormatada,
        "horario_partida": "${horaController.text}:00",
      });

      setState(() => loading = false);

      if (compResponse.statusCode == 200 || compResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Partida criada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final erro = jsonDecode(compResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${erro['detail'] ?? 'Erro'}")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      print("Erro: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro de conexão com o servidor")),
      );
    }
  }

  Widget _label(String texto) =>
      Text(texto, style: const TextStyle(color: branco, fontWeight: FontWeight.bold));

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<Map<String, String>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 5),
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: preto,
          style: const TextStyle(color: branco),
          decoration: InputDecoration(
            filled: true,
            fillColor: laranja,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          items: items
              .map((i) => DropdownMenuItem<T>(
                    value: i["value"] as T,
                    child: Text(i["label"]!, style: const TextStyle(color: branco)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _contador({
    required String label,
    required int value,
    required int min,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 5),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? onDecrement : null,
              icon: Icon(Icons.remove_circle,
                  color: value > min ? laranja : Colors.grey, size: 32),
            ),
            Text(
              "$value",
              style: const TextStyle(
                  color: branco, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle, color: laranja, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !loading,
      child: Scaffold(
        backgroundColor: preto,
        appBar: AppBar(
          title: const Text("CRIAÇÃO DE PARTIDA"),
          backgroundColor: laranja,
          foregroundColor: branco,
          centerTitle: true,
          automaticallyImplyLeading: !loading,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              _label("Local"),
              const SizedBox(height: 5),
              TextField(
                controller: localController,
                style: const TextStyle(color: branco),
                decoration: InputDecoration(
                  hintText: "Informe o local",
                  hintStyle: const TextStyle(color: branco, fontSize: 14),
                  filled: true,
                  fillColor: laranja,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              
              _label("Data"),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: selecionarData,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: laranja,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dataSelecionada == null
                            ? "Selecionar data"
                            : DateFormat('dd/MM/yyyy').format(dataSelecionada!),
                        style: const TextStyle(color: branco),
                      ),
                      const Icon(Icons.calendar_today, color: branco),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              
              _label("Horário"),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: selecionarHora,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: laranja,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        horaController.text.isEmpty
                            ? "Selecionar horário"
                            : horaController.text,
                        style: const TextStyle(color: branco),
                      ),
                      const Icon(Icons.access_time, color: branco),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              
              _dropdown<String>(
                label: "Visibilidade",
                value: visibilidade,
                items: visibilidades,
                onChanged: (v) => setState(() => visibilidade = v!),
              ),

              
              _dropdown<String>(
                label: "Tipo",
                value: tipo,
                items: tipos,
                onChanged: (v) => setState(() => tipo = v!),
              ),

            
              _contador(
                label: "Quantidade de times",
                value: qtdTimes,
                min: 2,
                onDecrement: () => setState(() => qtdTimes--),
                onIncrement: () => setState(() => qtdTimes++),
              ),

              
              _contador(
                label: "Máximo de jogadores",
                value: qtdMaxJogadores,
                min: 6,
                onDecrement: () => setState(() => qtdMaxJogadores--),
                onIncrement: () => setState(() => qtdMaxJogadores++),
              ),

              
              _label("Jogadores"),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: irParaBusca,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: laranja,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.person_add, color: branco),
                      SizedBox(width: 10),
                      Text("Convidar jogadores", style: TextStyle(color: branco)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (jogadoresSelecionados.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jogadoresSelecionados.length,
                  itemBuilder: (_, index) {
                    final j = jogadoresSelecionados[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: laranja,
                        child: Icon(Icons.person, color: branco),
                      ),
                      title: Text(j.nome, style: const TextStyle(color: branco)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            setState(() => jogadoresSelecionados.removeAt(index)),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

             
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : criarPartida,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: preto)
                      : const Text(
                          "CRIAR PARTIDA",
                          style: TextStyle(
                            color: preto,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
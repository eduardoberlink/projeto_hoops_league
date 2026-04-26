// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:front_end/services/api_services.dart';

class EditPartidaPage extends StatefulWidget {
  final int compId; // ← trocado de jogoId para compId

  const EditPartidaPage({super.key, required this.compId});

  @override
  State<EditPartidaPage> createState() => _EditPartidaPageState();
}

class _EditPartidaPageState extends State<EditPartidaPage> {
  static const preto = Color(0xFF1A1413);
  static const laranja = Color(0xFFED5223);
  static const branco = Color(0xFFFDFDFD);

  final localController = TextEditingController();
  final horarioController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  DateTime? dataSelecionada;
  bool loading = true;

  String visibilidade = "publico";
  String status = "em_aberto";
  int qtdTimes = 2;
  int qtdMaxJogadores = 10;

  final List<Map<String, String>> visibilidades = const [
    {"value": "publico", "label": "Público"},
    {"value": "privado", "label": "Privado"},
  ];

  final List<Map<String, String>> statusOpcoes = const [
    {"value": "em_aberto", "label": "Em aberto"},
    {"value": "confirmado", "label": "Confirmado"},
    {"value": "cancelado", "label": "Cancelado"},
    {"value": "encerrado", "label": "Encerrado"},
  ];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      final response = await ApiService.get("/comp/${widget.compId}");
      if (response != null) {
        setState(() {
          localController.text = response["local"] ?? "";
          visibilidade = response["visibilidade"] ?? "publico";
          status = response["status"] ?? "em_aberto";
          qtdTimes = response["qtd_times"] ?? 2;
          qtdMaxJogadores = response["qtd_max_jogadores"] ?? 10;

          // carrega data da partida se existir
          if (response["partida"] != null) {
            dataSelecionada =
                DateTime.tryParse(response["partida"]["data"] ?? "");
            final horario = response["partida"]["horario"] ?? "";
            horarioController.text =
                horario.length >= 5 ? horario.substring(0, 5) : horario;
          }

          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print("Erro ao carregar: $e");
      setState(() => loading = false);
    }
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;
    if (dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data")),
      );
      return;
    }
    if (horarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione o horário")),
      );
      return;
    }

    final dataFormatada = DateFormat('yyyy-MM-dd').format(dataSelecionada!);

    final sucesso = await ApiService.put("/comp/atualizar/${widget.compId}", {
      "local": localController.text.trim(),
      "status": status,
      "visibilidade": visibilidade,
      "qtd_times": qtdTimes,
      "tipo": "partida",
      "qtd_max_jogadores": qtdMaxJogadores,
      "data_partida": dataFormatada,
      "horario_partida": "${horarioController.text}:00",
    });

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Partida atualizada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao atualizar partida")),
      );
    }
  }

  Future<void> selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
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
        horarioController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _label(String texto) => Text(
        texto,
        style: const TextStyle(color: branco, fontWeight: FontWeight.bold),
      );

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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          items: items
              .map((i) => DropdownMenuItem<T>(
                    value: i["value"] as T,
                    child:
                        Text(i["label"]!, style: const TextStyle(color: branco)),
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
    if (loading) {
      return const Scaffold(
        backgroundColor: preto,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: preto,
      appBar: AppBar(
        backgroundColor: preto,
        foregroundColor: laranja,
        title: const Text("Editar Partida"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Local ──
              _label("Local"),
              const SizedBox(height: 5),
              TextFormField(
                controller: localController,
                style: const TextStyle(color: branco),
                decoration: InputDecoration(
                  hintText: "Informe o local",
                  hintStyle: const TextStyle(color: branco),
                  filled: true,
                  fillColor: laranja,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Informe o local" : null,
              ),

              const SizedBox(height: 15),

              // ── Data ──
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

              // ── Horário ──
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
                        horarioController.text.isEmpty
                            ? "Selecionar horário"
                            : horarioController.text,
                        style: const TextStyle(color: branco),
                      ),
                      const Icon(Icons.access_time, color: branco),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              _dropdown<String>(
                label: "Status",
                value: status,
                items: statusOpcoes,
                onChanged: (v) => setState(() => status = v!),
              ),

              
              _dropdown<String>(
                label: "Visibilidade",
                value: visibilidade,
                items: visibilidades,
                onChanged: (v) => setState(() => visibilidade = v!),
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

              const SizedBox(height: 20),

              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "SALVAR",
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
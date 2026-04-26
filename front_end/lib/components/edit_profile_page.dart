import 'package:flutter/material.dart';
import 'package:front_end/services/api_services.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nomeController = TextEditingController();
  final idadeController = TextEditingController();
  final alturaController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  String? posicaoSelecionada;
  bool loading = true;

  static const preto = Color(0xFF1A1413);
  static const laranja = Color(0xFFED5223);
  static const branco = Color(0xFFFDFDFD);

  final List<Map<String, String>> posicoes = const [
    {"value": "armador", "label": "Armador"},
    {"value": "ala_armador", "label": "Ala-Armador"},
    {"value": "ala", "label": "Ala"},
    {"value": "ala_pivo", "label": "Ala-Pivô"},
    {"value": "pivo", "label": "Pivô"},
  ];

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  void carregarUsuario() async {
    final user = await ApiService.getProfile();

    if (user != null) {
      nomeController.text = user["nome"] ?? "";
      idadeController.text = (user["idade"] ?? 0).toString();
      emailController.text = user["email"] ?? "";
      alturaController.text = (user["altura"] ?? 0).toString();
      posicaoSelecionada = user["posicao_preferida"];
    }

    setState(() => loading = false);
  }

  void salvar() async {
    setState(() => loading = true);

    final Map<String, dynamic> dados = {
      "nome": nomeController.text,
      "idade": int.tryParse(idadeController.text) ?? 0,
      "email": emailController.text,
      "altura": double.tryParse(alturaController.text) ?? 0,
      "posicao_preferida": posicaoSelecionada,
    };

    if (senhaController.text.isNotEmpty) {
      if (senhaController.text != confirmarSenhaController.text) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("As senhas não coincidem")),
        );
        return;
      }
      dados["senha"] = senhaController.text;
      dados["confirmar_senha"] = confirmarSenhaController.text;
    }

    final response = await ApiService.put("/auth/editar-me", dados);

    setState(() => loading = false);

    if (response) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil atualizado com sucesso")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erro ao atualizar perfil")));
    }
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
        title: const Text("Editar Perfil"),
        backgroundColor: preto,
        foregroundColor: laranja,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                style: TextStyle(color: branco),
                decoration: InputDecoration(
                  labelText: "Nome",
                  labelStyle: TextStyle(color: branco),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: branco),
                  ),
                  
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: branco,
                      width: 2,
                    ), 
                  ),
                ),
              ),

              const SizedBox(height: 13),

              TextField(
                controller: idadeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: branco),
                decoration: InputDecoration(
                  labelText: "Idade",
                  labelStyle: TextStyle(color: branco),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: branco),
                  ),
                  
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: branco,
                      width: 2,
                    ), 
                  ),
                ),
              ),

              const SizedBox(height: 13),

              TextField(
                controller: emailController,
                style: TextStyle(color: branco),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: branco),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: branco),
                  ),
                  
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: branco,
                      width: 2,
                    ), 
                  ),
                ),
              ),

              const SizedBox(height: 13),

              TextField(
                controller: alturaController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: branco),
                decoration:  InputDecoration(
                  labelText: "Altura",
                  labelStyle: TextStyle(color: branco),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: branco),
                  ),
                  
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: branco,
                      width: 2,
                    ), 
                  ),
                ),
              ),

              const SizedBox(height: 13),

              DropdownButtonFormField<String>(
                value: posicaoSelecionada,
                dropdownColor: preto,
                style:  TextStyle(color: branco),
                decoration:  InputDecoration(
                  labelText: "Posição",
                  labelStyle: TextStyle(color: branco),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: branco),
                  ),
                  
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: branco,
                      width: 2,
                    ), 
                  ),
                ),
                items: posicoes
                    .map(
                      (p) => DropdownMenuItem(
                        value: p["value"],
                        child: Text(p["label"]!),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => posicaoSelecionada = value);
                },
              ),

              const SizedBox(height: 300),

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
                    "Salvar",
                    style: TextStyle(
                      color: branco,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

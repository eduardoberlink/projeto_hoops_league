// ignore_for_file: use_build_context_synchronously, avoid_print
import 'package:flutter/material.dart';
import 'package:front_end/components/cadastro_page.dart';
import 'package:front_end/components/profile_page.dart';
import 'package:front_end/services/api_services.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController(); 
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool loading = false; 

  static const preto = Color(0xFF1A1413);
  static const laranja = Color(0xFFED5223);
  static const branco = Color(0xFFFDFDFD);

  final formKey = GlobalKey<FormState>();

 
  void login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    bool sucesso = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() => loading = false);

    if (sucesso) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email ou senha inválidos")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: laranja,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/logoPequena.png", height: 60),
                      SizedBox(width: 18),
                      Text(
                        "Hoops League",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: branco,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 50),

                const Text(
                  "ENTRAR",
                  style: TextStyle(
                    color: branco,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 30),

               
                TextFormField(
                  controller: emailController,
                  style: TextStyle(color: branco),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: branco),
                    prefixIcon: Icon(Icons.email, color: branco),
                    hintText: "Digite seu email",
                    hintStyle: TextStyle(color: branco),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: branco),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Informe o email";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),

               
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: TextStyle(color: branco),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: branco),
                    hintText: "Digite sua senha",
                    hintStyle: TextStyle(color: branco),
                    labelText: "Senha",
                    labelStyle: TextStyle(color: branco),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: branco,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: branco),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Informe a senha";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 30),

                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: preto,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: loading
                        ? CircularProgressIndicator(color: branco)
                        : Text(
                            "LOGIN",
                            style: TextStyle(fontSize: 16, color: branco),
                          ),
                  ),
                ),

                SizedBox(height: 70),

                Text(
                  "Não tem uma conta?",
                  style: TextStyle(color: Colors.grey[300]),
                ),

                SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CadastroPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: preto,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      "CRIAR CONTA",
                      style: TextStyle(fontSize: 16, color: branco),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
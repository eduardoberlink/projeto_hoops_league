// ignore_for_file: non_constant_identifier_names

class Jogador {
  String nome;
  String usuario;
  int overall;
  String foto_url;
  int idade;
  String email;
  double altura;

  Jogador({
    required this.nome,
    required this.usuario,
    required this.overall,
    this.foto_url = "",
    required this.idade,
    required this.email,
    required this.altura,
  });

  factory Jogador.fromJson(Map<String, dynamic> json) {
    return Jogador(
      nome: json['nome'] ?? "",
      usuario: json['user'] ?? "",
      overall: json['overall'] ?? 0,
      foto_url: json['foto_url'] ?? "",
      idade: json['idade'] ?? 0, 
      email: json['email'] ?? "",
      altura: (json['altura'] ?? 0).toDouble(), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'user': usuario, 
      'overall': overall,
      'foto_url': foto_url,
      'idade': idade,
      'email': email,
      'altura': altura,
    };
  }
}
// ignore_for_file: use_key_in_widget_constructors
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 👈 adicione
import 'package:front_end/services/api_services.dart';
import 'components/login_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.carregarToken(); // ← adicione isso
  runApp(HoopsLeague());
}

class HoopsLeague extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt', 'BR')],
      home: LoginPage(),
    );
  }
}

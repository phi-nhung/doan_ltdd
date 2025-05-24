import 'package:doan/login_provider.dart';
import 'package:doan/provider/account_provider.dart';
import 'package:doan/provider/cart_provider.dart';
import 'package:doan/provider/font_provider.dart';
import 'package:doan/provider/locale_provider.dart';
import 'package:doan/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doan/login.dart';

void main() {
  runApp(
    MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LoginProvider()),
    ChangeNotifierProvider(create: (_) => AccountProvider()), 
    ChangeNotifierProvider(create: (context) => CartProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
  ],
  child: const MyApp(),
)
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
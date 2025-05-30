import 'package:doan/login_provider.dart';
import 'package:doan/provider/account_provider.dart';
import 'package:doan/provider/cart_provider.dart';
import 'package:doan/provider/locale_provider.dart';
import 'package:doan/provider/theme_provider.dart';
import 'package:doan/provider/font_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:doan/login.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, LocaleProvider, FontProvider>(
      builder: (context, themeProvider, localeProvider, fontProvider, child) {
        final baseTheme = themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light();
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),

          theme: baseTheme.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(baseTheme.textTheme),
          ),
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('vi'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
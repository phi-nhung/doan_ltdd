import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/locale_provider.dart';
import '../provider/font_provider.dart';
import '../utils/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.get(context, 'settings'),style: TextStyle(color: Colors.white),),
            backgroundColor: Color.fromARGB(255, 107, 66, 38),
          ),
          body: ListView(
            children: [
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, child) => ListTile(
                  leading: Icon(Icons.language),
                  title: Text(AppLocalizations.get(context, 'language')),
                  trailing: DropdownButton<String>(
                    value: localeProvider.locale.languageCode,
                    items: [
                      DropdownMenuItem(
                        value: 'vi',
                        child: Text(AppLocalizations.get(context, 'vietnamese')),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(AppLocalizations.get(context, 'english')),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        localeProvider.setLocale(Locale(value));
                      }
                    },
                  ),
                ),
              ),
              Divider(),
              Consumer<FontProvider>(
                builder: (context, fontProvider, child) => ListTile(
                  leading: Icon(Icons.font_download),
                  title: Text(AppLocalizations.get(context, 'font')),
                  trailing: DropdownButton<String>(
                    value: fontProvider.availableFonts.contains(fontProvider.currentFont)
                        ? fontProvider.currentFont
                        : fontProvider.availableFonts.first,
                    items: fontProvider.availableFonts
                        .map((font) => DropdownMenuItem(
                              value: font,
                              child: Text(font),
                            ))
                        .toList(),
                    onChanged: (newFont) {
                      if (newFont != null) {
                        fontProvider.setFont(newFont);
                      }
                    },
                  ),
                ),
              ),
              Divider(),
              // Add App Version Info
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Phiên bản'), // Hardcoded for now as requested
                trailing: Text('1.0.0'), // Hardcoded version
              ),
              Divider(),
              // Add Support Contact Info
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Liên hệ hỗ trợ'), // Hardcoded for now
                trailing: Text('0971225040'), // Hardcoded hotline
              ),
            ],
          ),
        );
      },
    );
  }
}

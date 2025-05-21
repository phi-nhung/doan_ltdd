import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
import '../provider/locale_provider.dart';
import '../provider/font_provider.dart';
import '../utils/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get(context, 'settings')),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => ListView(
          children: [
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text(AppLocalizations.get(context, 'dark_mode')),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
              ),
            ),
            Divider(),
            Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) => ListTile(
                leading: Icon(Icons.language),
                title: Text(AppLocalizations.get(context, 'language')),
                trailing: DropdownButton<Locale>(
                  value: localeProvider.locale,
                  items: [
                    DropdownMenuItem(
                      value: const Locale('vi'),
                      child: Text('Tiếng Việt'),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (newLocale) {
                    if (newLocale != null) {
                      localeProvider.setLocale(newLocale);
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
          ],
        ),
      ),
    );
  }
}

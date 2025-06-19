import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/blocs/mobile_localization_bloc.dart';
import 'package:mobile_app/blocs/mobile_localization_event.dart';
import 'package:mobile_app/blocs/mobile_localization_state.dart';
import 'package:mobile_app/localization/app_localization.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/services/mock_mobile_translation_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MobileApp());
}

class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  static final List<Locale> supportedLocales = [
    const Locale('en', ''),
    const Locale('es', ''),
    const Locale('fr', ''),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MobileLocalizationBloc(MockMobileTranslationService())
            ..add(LoadInitialLocalization(supportedLocales.first)),
      child: BlocBuilder<MobileLocalizationBloc, MobileLocalizationState>(
        builder: (context, localizationState) {
          return MaterialApp(
            title: 'Dynamic Translations App',
            locale: localizationState.currentLocale,
            supportedLocales: supportedLocales,
            localizationsDelegates: [
              AppLocalizationsDelegate(
                allServerTranslations: localizationState.allServerTranslations,
              ),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode &&
                    (locale?.countryCode == null ||
                        supportedLocale.countryCode == locale?.countryCode)) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            home: HomeScreen(onRefresh: fetchTranslations),
          );
        },
      ),
    );
  }

  // Static method to fetch translations from admin API
  static Future<List<Map<String, dynamic>>> fetchTranslations() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.37:8080/translations'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('✅ Translations from API: $data');
      return List<Map<String, dynamic>>.from(data);
    } else {
      print('❌ Failed to fetch translations');
      return [];
    }
  }
}

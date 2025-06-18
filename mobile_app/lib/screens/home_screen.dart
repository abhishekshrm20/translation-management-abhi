import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/mobile_localization_bloc.dart';
import 'package:mobile_app/blocs/mobile_localization_event.dart';
import 'package:mobile_app/blocs/mobile_localization_state.dart';
import 'package:mobile_app/localization/app_localization.dart';
import 'package:mobile_app/main.dart';

class HomeScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? onRefresh;

  const HomeScreen({super.key, this.onRefresh});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _fetchedTranslations = [];

  Future<void> _fetchAndDisplayRawTranslations() async {
    if (widget.onRefresh != null) {
      final data = await widget.onRefresh!();
      setState(() {
        _fetchedTranslations = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationBloc = BlocProvider.of<MobileLocalizationBloc>(context);
    final currentLocale =
        context.watch<MobileLocalizationBloc>().state.currentLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('appTitle') ??
            'Translation App'),
        actions: [
          PopupMenuButton<Locale>(
            initialValue: currentLocale,
            onSelected: (Locale newLocale) {
              localizationBloc.add(SwitchLocaleEvent(newLocale));
            },
            itemBuilder: (BuildContext context) {
              return MobileApp.supportedLocales.map((Locale locale) {
                return PopupMenuItem<Locale>(
                  value: locale,
                  child: Text(locale.languageCode.toUpperCase()),
                );
              }).toList();
            },
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: BlocConsumer<MobileLocalizationBloc, MobileLocalizationState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${state.error}")),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.appLocalizations == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.appLocalizations == null) {
            return const Center(child: Text('Translations not loaded.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)!.translate('greeting'),
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.translate('farewell'),
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!
                              .translate('missing_key_example'),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        if (state.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  localizationBloc
                                      .add(UpdateTranslationsFromServer());
                                },
                          child: Text(AppLocalizations.of(context)!
                              .translate('refresh_translations_button')),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchAndDisplayRawTranslations,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('Show Raw Translations'),
                        ),
                        const SizedBox(height: 16),
                        if (_fetchedTranslations.isNotEmpty)
                          ..._fetchedTranslations.map((entry) {
                            return Card(
                              child: ListTile(
                                title: Text(entry['key']),
                                subtitle:
                                    Text(entry['translations']['en'] ?? '—'),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

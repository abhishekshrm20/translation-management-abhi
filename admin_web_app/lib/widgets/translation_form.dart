import 'dart:convert';
import 'package:admin_web_app/blocs/admin_translations_bloc.dart';
import 'package:admin_web_app/blocs/admin_translations_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:translation_domain/translation_domain.dart';

class TranslationFormDialog extends StatefulWidget {
  final BuildContext blocContext;
  final TranslationEntry? existingEntry;
  final List<String> supportedLocales;

  const TranslationFormDialog({
    super.key,
    required this.blocContext,
    this.existingEntry,
    required this.supportedLocales,
  });

  @override
  State<TranslationFormDialog> createState() => _TranslationFormDialogState();
}

class _TranslationFormDialogState extends State<TranslationFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keyController;
  late Map<String, TextEditingController> _localeControllers;
  late TabController _tabController;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _keyController =
        TextEditingController(text: widget.existingEntry?.key ?? '');
    _localeControllers = {
      for (var locale in widget.supportedLocales)
        locale: TextEditingController(
            text: widget.existingEntry?.translations[locale] ?? '')
    };
    _tabController =
        TabController(length: widget.supportedLocales.length, vsync: this);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _localeControllers.forEach((_, controller) => controller.dispose());
    _tabController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final key = _keyController.text.trim();
      final translations = <String, String>{};
      _localeControllers.forEach((locale, controller) {
        translations[locale] = controller.text.trim();
      });

      final adminBloc =
          BlocProvider.of<AdminTranslationsBloc>(widget.blocContext);

      if (_isEditing) {
        final updatedEntry = widget.existingEntry!.copyWith(
          key: key,
          translations: translations,
        );
        adminBloc.add(UpdateAdminTranslation(updatedEntry));
      } else {
        adminBloc.add(AddAdminTranslation(key, translations));
      }
      Navigator.of(context).pop();
    }
  }

  Future<String> _getAISuggestion(
      String key, String enText, String locale) async {
    const apiKey = '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';

    final prompt =
        "Suggest a professional translation for key '$key' into '$locale'. "
        "English: \"$enText\"";

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {
            "role": "user",
            "content":
                "Translate the phrase \"$enText\" into $locale. Context: UI label. Key: $key."
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception("AI Suggestion failed: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Translation' : 'Add New Translation'),
      content: SizedBox(
        width: 400,
        height: 380,
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Translation Key',
                  hintText: 'e.g., greeting, common.ok',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Key cannot be empty'
                    : null,
              ),
              const SizedBox(height: 16),
              DefaultTabController(
                length: widget.supportedLocales.length,
                child: Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: Theme.of(context).colorScheme.primary,
                        tabs: widget.supportedLocales
                            .map((locale) => Tab(text: locale.toUpperCase()))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: widget.supportedLocales.map((locale) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _localeControllers[locale],
                                      decoration: InputDecoration(
                                        labelText:
                                            'Translation for "${locale.toUpperCase()}"',
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.auto_fix_high),
                                    tooltip: 'AI Suggestion',
                                    onPressed: () async {
                                      final enText = _localeControllers['en']
                                              ?.text
                                              .trim() ??
                                          '';
                                      final key = _keyController.text.trim();

                                      if (enText.isEmpty || key.isEmpty) return;

                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(
                                            child: CircularProgressIndicator()),
                                      );

                                      try {
                                        final suggestion =
                                            await _getAISuggestion(
                                                key, enText, locale);
                                        _localeControllers[locale]?.text =
                                            suggestion;
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('❌ AI Error: $e')),
                                        );
                                      } finally {
                                        Navigator.of(context)
                                            .pop(); // Close loader
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text(_isEditing ? 'Save Changes' : 'Add Translation'),
          onPressed: _submitForm,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'dart:convert';
import 'models/rules_model.dart';

const Color _editorBackground = Color(0xFF1E1E1E);
const Color _panelBackground = Color(0xFF252526);
const Color _panelBorder = Color(0xFF3C3C3C);
//const Color _mutedText = Color(0xFF9E9E9E);

/// Enum representing the app's data state
enum AppState { loaded, unloaded }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'Automation Rules Viewer',
      theme: base.copyWith(
        scaffoldBackgroundColor: _editorBackground,
        canvasColor: _editorBackground,
        cardColor: _panelBackground,
        dividerColor: _panelBorder,
        primaryColor: Colors.deepPurple,
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(backgroundColor: Colors.deepPurple),
        textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const MyHomePage(title: 'Automation Rules Viewer'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// The loaded automation rules model, null when unloaded
  AutomationRuleList? _rulesModel;

  /// Currently selected rule index
  int? _selectedRuleIndex;

  /// Loaded filename
  String? _loadedFileName;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchPanelOpen = false;

  List<int> _calculateVisibleRuleIndices(String query) {
    final model = getRulesModel();
    if (model == null) return [];

    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<int>.generate(model.items.length, (index) => index);
    }

    return model.items.asMap().entries
        .where((entry) => entry.value.pipeline.any((stage) {
              final script = stage.script;
              return script != null && script.toLowerCase().contains(normalized);
            }))
        .map((entry) => entry.key)
        .toList();
  }

  List<int> get _visibleRuleIndices => _calculateVisibleRuleIndices(_searchQuery);

  void _updateSearchQuery(String query) {
    final normalized = query.trim();
    final visible = _calculateVisibleRuleIndices(normalized);

    setState(() {
      _searchQuery = normalized;
      if (_selectedRuleIndex == null || !visible.contains(_selectedRuleIndex)) {
        _selectedRuleIndex = visible.isNotEmpty ? visible.first : null;
      }
    });
  }

  void _applySearch() {
    _updateSearchQuery(_searchController.text);
  }

  AutomationRuleList? getRulesModel() {
    return _rulesModel;
  }

  /// Get the current app state based on whether a model is loaded
  AppState get _appState =>
      getRulesModel() != null ? AppState.loaded : AppState.unloaded;

  /// Get the currently selected rule
  AutomationRule? get _selectedRule {
    if (getRulesModel() == null || _selectedRuleIndex == null) return null;
    if (_selectedRuleIndex! >= getRulesModel()!.items.length) return null;
    return getRulesModel()!.items[_selectedRuleIndex!];
  }

  /// Load a model (typically from JSON)
  void _loadModel(AutomationRuleList model, {String? fileName}) {
    setState(() {
      _rulesModel = model;
      _selectedRuleIndex = model.items.isNotEmpty ? 0 : null;
      _loadedFileName = fileName;
    });
  }

  /// Unload the current model
  void _unloadModel() {
    setState(() {
      _rulesModel = null;
      _selectedRuleIndex = null;
      _loadedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _loadedFileName != null
        ? 'Automation Rules Viewer: $_loadedFileName'
        : widget.title;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(displayTitle),
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build the body based on the current app state
  Widget _buildBody() {
    if (_appState == AppState.unloaded) {
      return _buildUnloadedState();
    } else {
      return _buildLoadedState();
    }
  }

  /// UI for unloaded state
  Widget _buildUnloadedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No model loaded',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Load a JSON file to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// UI for loaded state - three section layout
  Widget _buildLoadedState() {
    return Column(
      children: [
        // Top section: Rule selector
        _buildRuleSelector(),
        // Main section: Split into left (JSON + params) and right (script)
        Expanded(
          child: Row(
            children: [
              // Left side: JSON and parameters
              Expanded(
                child: Column(
                  children: [
                    // Top left: Raw JSON
                    Expanded(
                      child: _buildJsonDisplay(),
                    ),
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    // Bottom left: Parameters
                    Expanded(
                      child: _buildParametersDisplay(),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                color: Colors.grey[300],
              ),
              // Right side: Script
              Expanded(
                child: _buildScriptDisplay(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the rule selector dropdown at the top
  Widget _buildRuleSelector() {
    if (getRulesModel() == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No rules available'),
      );
    }

    final visibleIndices = _visibleRuleIndices;
    final hasMatches = visibleIndices.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _searchPanelOpen = !_searchPanelOpen),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Search scripts',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  _searchPanelOpen ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          if (_searchPanelOpen)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search script text',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _applySearch,
                        ),
                      ),
                      onSubmitted: (_) => _applySearch(),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        _updateSearchQuery('');
                      },
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (!hasMatches)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                getRulesModel()!.items.isEmpty
                    ? 'No rules available'
                    : 'No matching scripts found',
                style: const TextStyle(color: Colors.white70),
              ),
            )
          else
            Row(
              children: [
                const Text('Select Rule:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedRuleIndex,
                    items: visibleIndices.map((index) {
                      final rule = getRulesModel()!.items[index];
                      final displayName =
                          rule.description.isNotEmpty ? rule.description : 'Rule $index';
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(displayName),
                      );
                    }).toList(),
                    dropdownColor: Theme.of(context).cardColor,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (newIndex) {
                      if (newIndex != null) {
                        setState(() {
                          _selectedRuleIndex = newIndex;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build the raw JSON display area
  Widget _buildJsonDisplay() {
    if (_selectedRule == null) {
      return const Center(child: Text('No rule selected'));
    }

    final jsonMap = _selectedRule!.toJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: const Text(
              'Rule JSON',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: HighlightView(
                  jsonString,
                  language: 'json',
                  theme: atomOneDarkTheme,
                  padding: const EdgeInsets.all(8),
                  textStyle: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the parameters display area
  Widget _buildParametersDisplay() {
    if (_selectedRule == null) {
      return const Center(child: Text('No rule selected'));
    }

    final rule = _selectedRule!;
    final params = rule.parameterValues;

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Text(
              'Parameters (${params.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Expanded(
            child: params.isEmpty
                ? const Center(
                    child: Text(
                      'No parameters',
                      style: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: params.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Courier New',
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptText(String script) {
    if (_searchQuery.isEmpty) {
      return SelectableText(
        script,
        style: const TextStyle(
          fontFamily: 'Courier New',
          fontSize: 11,
          color: Colors.white70,
        ),
      );
    }

    final query = _searchQuery.toLowerCase();
    final matches = RegExp(RegExp.escape(query), caseSensitive: false).allMatches(script);
    if (matches.isEmpty) {
      return SelectableText(
        script,
        style: const TextStyle(
          fontFamily: 'Courier New',
          fontSize: 11,
          color: Colors.white70,
        ),
      );
    }

    final spans = <TextSpan>[];
    var lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: script.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: script.substring(match.start, match.end),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontFamily: 'Courier New',
          fontSize: 11,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < script.length) {
      spans.add(TextSpan(text: script.substring(lastEnd)));
    }

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Courier New',
          fontSize: 11,
          color: Colors.white70,
        ),
        children: spans,
      ),
    );
  }

  /// Build the script display area
  Widget _buildScriptDisplay() {
    if (_selectedRule == null) {
      return const Center(child: Text('No rule selected'));
    }

    final rule = _selectedRule!;
    final script = rule.pipeline
        .where((stage) => stage.script != null)
        .map((stage) => stage.script!)
        .toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Text(
              'Scripts (${script.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Expanded(
            child: script.isEmpty
                ? const Center(
                    child: Text(
                      'No scripts in pipeline',
                      style: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: script.length == 1
                          ? _buildScriptText(script[0])
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                script.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Script ${index + 1}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildScriptText(script[index]),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build the floating action button based on state
  Widget? _buildFloatingActionButton() {
    if (_appState == AppState.unloaded) {
      return FloatingActionButton(
        onPressed: () => _showLoadOptions(),
        tooltip: 'Load JSON',
        child: const Icon(Icons.add),
      );
    } else {
      return FloatingActionButton(
        onPressed: _unloadModel,
        tooltip: 'Unload',
        child: const Icon(Icons.close),
      );
    }
  }

  /// Show options for loading a model
  void _showLoadOptions() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select JSON Rules File',
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        if (file.bytes == null) {
          throw Exception('Unable to read selected file bytes.');
        }

        final contents = utf8.decode(file.bytes!);

        final json = jsonDecode(contents) as Map<String, dynamic>;
        final model = AutomationRuleList.fromJson(json);
        _loadModel(model, fileName: file.name);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded ${model.items.length} rules')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading file: $e')),
        );
      }
    }
  }
}

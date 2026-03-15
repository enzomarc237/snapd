import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_agent.dart';

/// Manages AI agent configurations with CRUD and JSON persistence.
class AiAgentService extends ChangeNotifier {
  static const String _fileName = 'ai_agents.json';
  static const _uuid = Uuid();

  List<AiAgent> _agents = [];
  bool _isLoaded = false;

  List<AiAgent> get agents => List.unmodifiable(_agents);
  List<AiAgent> get enabledAgents =>
      _agents.where((a) => a.isEnabled).toList();
  bool get isLoaded => _isLoaded;

  /// Loads agents from disk.
  Future<void> load() async {
    final file = await _configFile();
    if (!await file.exists()) {
      _agents = [];
      _isLoaded = true;
      notifyListeners();
      return;
    }
    try {
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents) as List<dynamic>;
      _agents = jsonList
          .cast<Map<String, dynamic>>()
          .map(AiAgent.fromJson)
          .toList();
    } catch (e) {
      debugPrint('AiAgentService: failed to load agents – $e');
      _agents = [];
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Adds a new [AiAgent].
  Future<AiAgent> add({
    required String name,
    required AiAgentType type,
    required String model,
    String? apiKey,
    String? baseUrl,
    String systemPrompt = '',
  }) async {
    _assertLoaded();
    final now = DateTime.now();
    final agent = AiAgent(
      id: _uuid.v4(),
      name: name.trim(),
      type: type,
      model: model.trim(),
      apiKey: apiKey?.trim(),
      baseUrl: baseUrl?.trim(),
      systemPrompt: systemPrompt.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _agents.add(agent);
    await _persist();
    notifyListeners();
    return agent;
  }

  /// Updates an existing [AiAgent] by [id].
  Future<void> update(
    String id, {
    String? name,
    AiAgentType? type,
    String? model,
    String? apiKey,
    String? baseUrl,
    String? systemPrompt,
    bool? isEnabled,
  }) async {
    _assertLoaded();
    final index = _agents.indexWhere((a) => a.id == id);
    if (index == -1) throw ArgumentError('Agent "$id" not found.');
    final existing = _agents[index];
    _agents[index] = existing.copyWith(
      name: name?.trim() ?? existing.name,
      type: type ?? existing.type,
      model: model?.trim() ?? existing.model,
      apiKey: apiKey?.trim() ?? existing.apiKey,
      baseUrl: baseUrl?.trim() ?? existing.baseUrl,
      systemPrompt: systemPrompt?.trim() ?? existing.systemPrompt,
      isEnabled: isEnabled ?? existing.isEnabled,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  /// Deletes the agent with [id].
  Future<void> delete(String id) async {
    _assertLoaded();
    _agents.removeWhere((a) => a.id == id);
    await _persist();
    notifyListeners();
  }

  /// Toggles the [isEnabled] flag on the agent with [id].
  Future<void> toggleEnabled(String id) async {
    _assertLoaded();
    final index = _agents.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _agents[index] = _agents[index].copyWith(
      isEnabled: !_agents[index].isEnabled,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<File> _configFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _persist() async {
    final file = await _configFile();
    final json = jsonEncode(_agents.map((a) => a.toJson()).toList());
    await file.writeAsString(json, flush: true);
  }

  void _assertLoaded() {
    if (!_isLoaded) {
      throw StateError('AiAgentService has not been loaded yet. Call load().');
    }
  }
}

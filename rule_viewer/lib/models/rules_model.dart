/// Model classes for Targetprocess Automation Rules
/// 
/// This file contains the data models to represent automation rules exported from
/// Targetprocess. Each rule contains a pipeline with sources, filters, and actions.
library;

/// Root model containing a list of automation rules
class AutomationRuleList {
  /// List of automation rule objects
  final List<AutomationRule> items;

  AutomationRuleList({required this.items});

  /// Parse from JSON map
  factory AutomationRuleList.fromJson(Map<String, dynamic> json) {
    return AutomationRuleList(
      items: (json['items'] as List?)
          ?.map((item) => AutomationRule.fromJson(item))
          .toList() ??
          [],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// Represents a single automation rule in Targetprocess
class AutomationRule {
  /// Unique identifier for the rule
  final String id;

  /// Display name (often empty)
  final String name;

  /// Human-readable description of what the rule does
  final String description;

  /// Service that owns this rule (typically "business-rules")
  final String ownerService;

  /// Identity of the service instance that owns this rule
  final String ownerIdentity;

  /// Pipeline stages defining the rule flow (sources, filters, actions)
  final List<PipelineStage> pipeline;

  /// Whether this rule is currently disabled
  final bool disabled;

  /// Version number of this rule
  final int version;

  /// ISO 8601 timestamp when the rule was created
  final String createDate;

  /// ISO 8601 timestamp of the last modification
  final String lastChangeDate;

  /// Custom metadata about the rule (migration info, backups, etc)
  final CustomData? customData;

  /// Parameter definitions for rule configuration
  final Map<String, dynamic> parameterDefinitions;

  /// Current parameter values
  final Map<String, dynamic> parameterValues;

  /// Policy configurations
  final Map<String, dynamic> policies;

  /// Whether this rule was created by an organization admin
  final bool createdByOrganizationAdmin;

  AutomationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerService,
    required this.ownerIdentity,
    required this.pipeline,
    required this.disabled,
    required this.version,
    required this.createDate,
    required this.lastChangeDate,
    this.customData,
    required this.parameterDefinitions,
    required this.parameterValues,
    required this.policies,
    required this.createdByOrganizationAdmin,
  });

  /// Parse from JSON map
  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ownerService: json['ownerService'] as String? ?? '',
      ownerIdentity: json['ownerIdentity'] as String? ?? '',
      pipeline: (json['pipeline'] as List?)
          ?.map((item) => PipelineStage.fromJson(item))
          .toList() ??
          [],
      disabled: json['disabled'] as bool? ?? false,
      version: json['version'] as int? ?? 0,
      createDate: json['createDate'] as String? ?? '',
      lastChangeDate: json['lastChangeDate'] as String? ?? '',
      customData: json['customData'] != null
          ? CustomData.fromJson(json['customData'])
          : null,
      parameterDefinitions:
          json['parameterDefinitions'] as Map<String, dynamic>? ?? {},
      parameterValues: json['parameterValues'] as Map<String, dynamic>? ?? {},
      policies: json['policies'] as Map<String, dynamic>? ?? {},
      createdByOrganizationAdmin:
          json['createdByOrganizationAdmin'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerService': ownerService,
      'ownerIdentity': ownerIdentity,
      'pipeline': pipeline.map((stage) => stage.toJson()).toList(),
      'disabled': disabled,
      'version': version,
      'createDate': createDate,
      'lastChangeDate': lastChangeDate,
      'customData': customData?.toJson(),
      'parameterDefinitions': parameterDefinitions,
      'parameterValues': parameterValues,
      'policies': policies,
      'createdByOrganizationAdmin': createdByOrganizationAdmin,
    };
  }
}

/// Represents a single stage in the rule pipeline
/// Can be a source (trigger), filter (condition), or action (operation)
class PipelineStage {
  /// Type of the pipeline stage (e.g., "source:targetprocess:EntityChanged", "action:JavaScript")
  final String type;

  /// Entity types this source applies to (for source stages)
  final List<String> entityTypes;

  /// Modifications to trigger on (for source stages)
  final Modifications? modifications;

  /// JavaScript code to execute (for action stages)
  final String? script;

  /// Optional name/identifier for the stage
  final String? name;

  /// Filter condition (for filter stages) - can contain nested logic
  final Map<String, dynamic>? condition;

  /// All additional properties not explicitly modeled
  final Map<String, dynamic> _extra;

  PipelineStage({
    required this.type,
    this.entityTypes = const [],
    this.modifications,
    this.script,
    this.name,
    this.condition,
    Map<String, dynamic>? extra,
  }) : _extra = extra ?? {};

  /// Parse from JSON map
  factory PipelineStage.fromJson(Map<String, dynamic> json) {
    return PipelineStage(
      type: json['type'] as String? ?? '',
      entityTypes: (json['entityTypes'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      modifications: json['modifications'] != null
          ? Modifications.fromJson(json['modifications'])
          : null,
      script: json['script'] as String?,
      name: json['name'] as String?,
      condition: _extractCondition(json),
      extra: _extractExtra(json),
    );
  }

  /// Extract the main condition structure if present
  static Map<String, dynamic>? _extractCondition(Map<String, dynamic> json) {
    if (json.containsKey('or') || json.containsKey('and')) {
      final condition = <String, dynamic>{};
      if (json.containsKey('or')) condition['or'] = json['or'];
      if (json.containsKey('and')) condition['and'] = json['and'];
      return condition;
    }
    return null;
  }

  /// Extract properties not explicitly modeled
  static Map<String, dynamic> _extractExtra(Map<String, dynamic> json) {
    final extra = <String, dynamic>{};
    final knownKeys = {
      'type',
      'entityTypes',
      'modifications',
      'script',
      'name',
      'or',
      'and'
    };
    json.forEach((key, value) {
      if (!knownKeys.contains(key)) {
        extra[key] = value;
      }
    });
    return extra;
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final json = {
      'type': type,
      if (entityTypes.isNotEmpty) 'entityTypes': entityTypes,
      if (modifications != null) 'modifications': modifications?.toJson(),
      if (script != null) 'script': script,
      if (name != null) 'name': name,
      ..._extra,
    };
    if (condition != null) {
      json.addAll(condition!);
    }
    return json;
  }
}

/// Defines what entity modifications trigger the source
class Modifications {
  /// Whether creation of an entity triggers this rule
  final bool? created;

  /// List of fields that, when updated, trigger this rule
  final List<String> updated;

  Modifications({
    this.created,
    this.updated = const [],
  });

  /// Parse from JSON map
  factory Modifications.fromJson(Map<String, dynamic> json) {
    final updated = json['updated'];
    List<String> updatedList = [];
    
    if (updated is List) {
      updatedList = updated.map((e) => e.toString()).toList();
    } else if (updated is bool) {
      // Handle case where 'updated' is a boolean (should be empty list)
      updatedList = [];
    }
    
    return Modifications(
      created: json['created'] as bool?,
      updated: updatedList,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (created != null) 'created': created,
      if (updated.isNotEmpty) 'updated': updated,
    };
  }
}

/// Custom metadata attached to a rule
class CustomData {
  /// Backup information from migration
  final SourceBackup? sourceBackup;

  /// Information about migration from rule engine v1
  final RuleEngineV1Migrator? ruleEngineV1Migrator;

  /// Any other custom properties
  final Map<String, dynamic> _extra;

  CustomData({
    this.sourceBackup,
    this.ruleEngineV1Migrator,
    Map<String, dynamic>? extra,
  }) : _extra = extra ?? {};

  /// Parse from JSON map
  factory CustomData.fromJson(Map<String, dynamic> json) {
    return CustomData(
      sourceBackup: json['sourceBackup'] != null
          ? SourceBackup.fromJson(json['sourceBackup'])
          : null,
      ruleEngineV1Migrator: json['ruleEngineV1Migrator'] != null
          ? RuleEngineV1Migrator.fromJson(json['ruleEngineV1Migrator'])
          : null,
      extra: _extractExtra(json),
    );
  }

  /// Extract properties not explicitly modeled
  static Map<String, dynamic> _extractExtra(Map<String, dynamic> json) {
    final extra = <String, dynamic>{};
    final knownKeys = {'sourceBackup', 'ruleEngineV1Migrator'};
    json.forEach((key, value) {
      if (!knownKeys.contains(key)) {
        extra[key] = value;
      }
    });
    return extra;
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (sourceBackup != null) 'sourceBackup': sourceBackup?.toJson(),
      if (ruleEngineV1Migrator != null)
        'ruleEngineV1Migrator': ruleEngineV1Migrator?.toJson(),
      ..._extra,
    };
  }
}

/// Information about a backup from migration
class SourceBackup {
  /// Unique identifier for the backup
  final String backupId;

  /// ID of the original rule before migration
  final String originalRuleId;

  /// Version of the original rule
  final int originalRuleVersion;

  SourceBackup({
    required this.backupId,
    required this.originalRuleId,
    required this.originalRuleVersion,
  });

  /// Parse from JSON map
  factory SourceBackup.fromJson(Map<String, dynamic> json) {
    return SourceBackup(
      backupId: json['backupId'] as String? ?? '',
      originalRuleId: json['originalRuleId'] as String? ?? '',
      originalRuleVersion: json['originalRuleVersion'] as int? ?? 0,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'backupId': backupId,
      'originalRuleId': originalRuleId,
      'originalRuleVersion': originalRuleVersion,
    };
  }
}

/// Information about migration from rule engine v1
class RuleEngineV1Migrator {
  /// ID of the rule in the old rule engine
  final int ruleId;

  /// Kind/type of the old rule
  final String ruleKind;

  /// Signature/checksum of the rule
  final String signature;

  RuleEngineV1Migrator({
    required this.ruleId,
    required this.ruleKind,
    required this.signature,
  });

  /// Parse from JSON map
  factory RuleEngineV1Migrator.fromJson(Map<String, dynamic> json) {
    return RuleEngineV1Migrator(
      ruleId: json['ruleId'] as int? ?? 0,
      ruleKind: json['ruleKind'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'ruleKind': ruleKind,
      'signature': signature,
    };
  }
}
import 'package:flutter_test/flutter_test.dart';

import 'package:rule_viewer/main.dart';
import 'package:rule_viewer/models/rules_model.dart';

void main() {
  group('rule ordering helpers', () {
    final model = AutomationRuleList(items: [
      AutomationRule(
        id: '1',
        name: '',
        description: 'First rule',
        ownerService: '',
        ownerIdentity: '',
        pipeline: const [],
        disabled: false,
        version: 1,
        createDate: '',
        lastChangeDate: '2024-02-01T00:00:00.000Z',
        parameterDefinitions: const {},
        parameterValues: const {},
        policies: const {},
        createdByOrganizationAdmin: false,
      ),
      AutomationRule(
        id: '2',
        name: '',
        description: 'Second rule',
        ownerService: '',
        ownerIdentity: '',
        pipeline: const [],
        disabled: false,
        version: 1,
        createDate: '',
        lastChangeDate: '2025-01-01T00:00:00.000Z',
        parameterDefinitions: const {},
        parameterValues: const {},
        policies: const {},
        createdByOrganizationAdmin: false,
      ),
      AutomationRule(
        id: '3',
        name: '',
        description: 'Third rule',
        ownerService: '',
        ownerIdentity: '',
        pipeline: const [],
        disabled: false,
        version: 1,
        createDate: '',
        lastChangeDate: '2023-03-01T00:00:00.000Z',
        parameterDefinitions: const {},
        parameterValues: const {},
        policies: const {},
        createdByOrganizationAdmin: false,
      ),
    ]);

    test('keeps the natural order when the toggle is off', () {
      expect(sortRuleIndices(model, [0, 1, 2], sortByLastModified: false), [0, 1, 2]);
    });

    test('sorts rules by last modification date when the toggle is on', () {
      expect(sortRuleIndices(model, [0, 1, 2], sortByLastModified: true), [1, 0, 2]);
    });
  });
}

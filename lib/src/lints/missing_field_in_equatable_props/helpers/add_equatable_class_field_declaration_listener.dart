import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../../constants/equatable_props_field_name.dart';
import '../../../helpers/get_equatable_props_expression_infos.dart';

/// Extension to add a specific listener for equatable class fields
extension AddEquatableClassFieldDeclarationListener on LintRuleNodeRegistry {
  /// Getter to add a specific listener for equatable class fields
  void addEquatableClassFieldDeclaration(
    void Function({
      required FieldDeclaration fieldNode,
      required FieldElement2 fieldElement,
      required ClassDeclaration classNode,
      required List<FieldElement2> watchableFields,
      required EquatablePropsExpressionDetails? equatablePropsExpressionDetails,
    }) listener, {
    bool Function(FieldDeclaration)? optionnalPreCheck,
  }) {
    addFieldDeclaration((fieldNode) {
      if (optionnalPreCheck != null) {
        final canContinue = optionnalPreCheck(fieldNode);
        if (!canContinue) {
          return;
        }
      }

      final classNode = fieldNode.parent;

      if (classNode is! ClassDeclaration) {
        return;
      }

      final classElement = classNode.declaredFragment?.element;
      if (classElement == null) {
        return;
      }

      const mixinTypeChecker =
          TypeChecker.fromName('EquatableMixin', packageName: 'equatable');
      const classTypeChecker =
          TypeChecker.fromName('Equatable', packageName: 'equatable');
      final classType = classElement.thisType;

      final isEquatable = mixinTypeChecker.isAssignableFromType(classType) ||
          classTypeChecker.isAssignableFromType(classType);

      if (!isEquatable) {
        return;
      }

      final watchableFields = classElement.fields2
          .where((field) => !field.isSynthetic)
          .where((field) => !field.isStatic)
          .where((field) => field.displayName != equatablePropsFieldName)
          .toList();

      final fieldElement = watchableFields.firstWhereOrNull(
        (field) =>
            fieldNode.toString().contains('$field ') ||
            fieldNode.toString().contains('$field;'),
      );

      if (fieldElement == null) {
        return;
      }

      final equatablePropsExpressionDetails =
          classNode.equatablePropsExpressionDetails;

      listener(
        fieldNode: fieldNode,
        fieldElement: fieldElement,
        classNode: classNode,
        watchableFields: watchableFields,
        equatablePropsExpressionDetails: equatablePropsExpressionDetails,
      );
    });
  }
}

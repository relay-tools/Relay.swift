/** @jsx swiftJSX */

import { swiftJSX, Fragment, renderSwift } from './swiftJSX';
import { TypeGenerator, Schema, IRVisitor } from 'relay-compiler';
import { RunState } from './RunState';
import * as RefetchableFragmentTransform from 'relay-compiler/lib/transforms/RefetchableFragmentTransform';
import { TypeGeneratorOptions } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { NodeVisitor } from 'relay-compiler/lib/core/IRVisitor';
import {
  ProtocolNode,
  InputStructNode,
  ReadableStructNode,
  FieldNode,
  EnumNode,
  ReadableTypeNode,
  InlineFragmentNode,
} from './SwiftGeneratorDataTypes';
import {
  transformInputType,
  transformScalarType,
  transformObjectType,
} from './transforms';
import { State } from 'State';
import { DataType } from './components/DataTypes';

export function SwiftGenerator(runState: RunState): TypeGenerator {
  return {
    generate(schema, node, options) {
      const ast = IRVisitor.visit(node, createVisitor(schema, options));

      const code = (
        <Fragment>
          {ast
            .filter(node => {
              if (node.kind === 'enum' || node.kind === 'inputStruct') {
                if (runState.hasGeneratedType(node.name)) {
                  return false;
                }

                runState.addGeneratedType(node.name);
              }
              return true;
            })
            .map(node => (
              <DataType node={node} />
            ))}
        </Fragment>
      );

      return renderSwift(code);
    },

    transforms: [RefetchableFragmentTransform.transform],
  };
}

function createVisitor(
  schema: Schema,
  options: TypeGeneratorOptions
): NodeVisitor {
  const state: State = {
    usedEnums: {},
    generatedInputObjects: {},
    ...options,
  };
  return {
    leave: {
      Root(node) {
        const variables: InputStructNode = {
          kind: 'inputStruct',
          name: `${node.name}.Variables`,
          isRootVariables: true,
          fields: node.argumentDefinitions.map(arg => {
            return {
              kind: 'field',
              fieldName: arg.name,
              typeName: transformInputType(schema, arg.type, state),
            };
          }),
        };

        const fields: FieldNode[] = node.selections as any;
        const struct: ReadableStructNode = {
          kind: 'readableStruct',
          name: `${node.name}.Data`,
          fields,
          childTypes: fields
            .filter(selection => selection.childType != null)
            .map(selection => selection.childType),
          extends: fields
            .filter(selection => selection.protocolName != null)
            .map(selection => selection.protocolName),
        };

        const enumDefs: EnumNode[] = Object.keys(state.usedEnums).map(
          enumName => {
            return {
              kind: 'enum',
              name: enumName,
              values: schema.getEnumValues(state.usedEnums[enumName]),
            };
          }
        );

        return [
          variables,
          ...Object.values(state.generatedInputObjects),
          struct,
          ...enumDefs,
        ];
      },
      Fragment(node) {
        let typeKind: ReadableTypeNode['kind'] = 'readableStruct';

        // Only generate an enum here if there are actually inline fragments in the selections.
        // If the type is a union or interface but only contains fragment spreads or fields from
        // the interface, then we should represent it as a struct.
        if (
          node.selections.some((field: any) => field.kind === 'inlineFragment')
        ) {
          if (schema.isUnion(node.type)) {
            typeKind = 'readableUnion';
          } else if (schema.isInterface(node.type)) {
            typeKind = 'readableInterface';
          }
        }

        const fields: FieldNode[] = node.selections as any;
        const struct: ReadableTypeNode = {
          kind: typeKind,
          name: `${node.name}.Data`,
          originalTypeName: schema.getTypeString(node.type),
          fields,
          childTypes: fields
            .filter(selection => selection.childType != null)
            .map(selection => selection.childType),
          extends: fields
            .filter(selection => selection.protocolName != null)
            .map(selection => selection.protocolName),
        };

        const enumDefs: EnumNode[] = Object.keys(state.usedEnums).map(
          enumName => {
            return {
              kind: 'enum',
              name: enumName,
              values: schema.getEnumValues(state.usedEnums[enumName]),
            };
          }
        );

        const protocol: ProtocolNode = {
          kind: 'protocol',
          name: `${node.name}_Key`,
          alias: `${node.name}.Key`,
          fields: [
            {
              kind: 'field',
              fieldName: `fragment_${node.name}`,
              typeName: `FragmentPointer`,
            },
          ],
        };

        return [struct, protocol, ...enumDefs];
      },
      ScalarField(node): FieldNode {
        const typeName = transformScalarType(schema, node.type, state);
        return {
          kind: 'field',
          fieldName: node.alias,
          typeName: typeName,
          protocolName:
            node.alias === 'id' && typeName === 'String'
              ? 'Identifiable'
              : undefined,
        };
      },
      LinkedField(node): FieldNode {
        const {
          typeString,
          baseTypeString,
          originalTypeName,
          kind,
        } = transformObjectType(schema, node.type, node.alias, state);

        let childTypeKind: ReadableTypeNode['kind'] = 'readableStruct';
        const fields: (
          | FieldNode
          | InlineFragmentNode
        )[] = node.selections as any;

        // Only generate an enum here if there are actually inline fragments in the selections.
        // If the type is a union or interface but only contains fragment spreads or fields from
        // the interface, then we should represent it as a struct.
        if (fields.some(field => field.kind === 'inlineFragment')) {
          if (kind === 'Union') {
            childTypeKind = 'readableUnion';
          } else if (kind === 'Interface') {
            childTypeKind = 'readableInterface';
          }
        }

        // If the field is a connection field, add protocols to the edge and node types
        // to turn the connection field into a collection.
        if (
          node.directives?.some(directive => directive.name === 'connection')
        ) {
          const edgesField = fields.find(
            (field): field is FieldNode =>
              field.kind === 'field' && field.fieldName === 'edges'
          );
          if (edgesField && edgesField.childType) {
            const nodeField = (edgesField.childType.fields as (
              | FieldNode
              | InlineFragmentNode
            )[]).find(
              (field): field is FieldNode =>
                field.kind === 'field' && field.fieldName === 'node'
            );
            if (nodeField && nodeField.childType) {
              // protocolName gets added to the type containing the field
              edgesField.protocolName = 'ConnectionCollection';
              edgesField.childType.extends.push('ConnectionEdge');
              nodeField.childType.extends.push('ConnectionNode');
            }
          }
        }

        return {
          kind: 'field',
          fieldName: node.alias,
          typeName: typeString,
          childType: {
            kind: childTypeKind,
            name: baseTypeString,
            originalTypeName,
            fields: fields as any,
            childTypes: fields
              .filter(
                (selection): selection is FieldNode =>
                  selection.childType != null
              )
              .map(selection => selection.childType),
            extends: fields
              .filter(
                (selection): selection is FieldNode =>
                  selection.kind === 'field' && selection.protocolName != null
              )
              .map(selection => selection.protocolName),
          },
        };
      },
      FragmentSpread(node): FieldNode {
        return {
          kind: 'field',
          fieldName: `fragment_${node.name}`,
          typeName: `FragmentPointer`,
          fragmentName: node.name,
          protocolName: `${node.name}_Key`,
        };
      },
      InlineFragment(node): InlineFragmentNode {
        const { baseTypeString } = transformObjectType(
          schema,
          node.typeCondition,
          '',
          state
        );
        const fields: FieldNode[] = node.selections as any;
        return {
          kind: 'inlineFragment',
          childType: {
            kind: 'readableStruct',
            name: baseTypeString,
            fields,
            childTypes: fields
              .filter(selection => selection.childType != null)
              .map(selection => selection.childType),
            extends: fields
              .filter(selection => selection.protocolName != null)
              .map(selection => selection.protocolName),
          },
        };
      },
    },
  };
}

import { TypeGenerator, Schema, TypeID, IRVisitor } from 'relay-compiler';
import { RunState } from './RunState';
import * as RefetchableFragmentTransform from 'relay-compiler/lib/transforms/RefetchableFragmentTransform';
import { TypeGeneratorOptions } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { NodeVisitor } from 'relay-compiler/lib/core/IRVisitor';
import { indent } from './util';

export function SwiftGenerator(runState: RunState): TypeGenerator {
  return {
    generate(schema, node, options) {
      const ast = IRVisitor.visit(node, createVisitor(schema, options));

      const typeText = ast
        .filter(node => {
          if (node.kind === 'enum' || node.kind === 'inputStruct') {
            if (runState.hasGeneratedType(node.name)) {
              return false;
            }

            runState.addGeneratedType(node.name);
          }
          return true;
        })
        .map(node => makeTypeNode(node, 0))
        .join('\n');

      return typeText;
    },

    transforms: [RefetchableFragmentTransform.transform],
  };
}

interface State extends TypeGeneratorOptions {
  usedEnums: Record<string, string>;
  generatedInputObjects: Record<string, any>;
}

function createVisitor(
  schema: Schema,
  options: TypeGeneratorOptions
): NodeVisitor {
  const state = {
    usedEnums: {},
    generatedInputObjects: {},
    ...options,
  };
  return {
    leave: {
      Root(node) {
        const variables = {
          kind: 'inputStruct',
          name: `${node.name}.Variables`,
          fields: node.argumentDefinitions.map(arg => {
            return {
              kind: 'field',
              fieldName: arg.name,
              typeName: transformInputType(schema, arg.type, state),
            };
          }),
        };

        const struct = {
          kind: 'readableStruct',
          name: `${node.name}.Data`,
          fields: node.selections,
          childTypes: (node.selections as any)
            .filter(selection => selection.childType != null)
            .map(selection => selection.childType),
          extends: (node.selections as any)
            .filter(selection => selection.protocolName != null)
            .map(selection => selection.protocolName),
        };

        const enumDefs = Object.keys(state.usedEnums).map(enumName => {
          return {
            kind: 'enum',
            name: enumName,
            values: schema.getEnumValues(state.usedEnums[enumName]),
          };
        });

        // console.log(state.usedInputObjects);

        return [
          variables,
          ...Object.values(state.generatedInputObjects),
          struct,
          ...enumDefs,
        ];
      },
      Fragment(node) {
        const struct = {
          kind: 'readableStruct',
          name: `${node.name}.Data`,
          fields: node.selections,
          childTypes: node.selections
            .filter((selection: any) => selection.childType != null)
            .map((selection: any) => selection.childType),
          extends: node.selections
            .filter((selection: any) => selection.protocolName != null)
            .map((selection: any) => selection.protocolName),
        };

        const enumDefs = Object.keys(state.usedEnums).map(enumName => {
          return {
            kind: 'enum',
            name: enumName,
            values: schema.getEnumValues(state.usedEnums[enumName]),
          };
        });

        const protocol = {
          kind: 'protocol',
          name: `${node.name}_Key`,
          alias: `${node.name}.Key`,
          fields: [
            {
              fieldName: `fragment_${node.name}`,
              typeName: `FragmentPointer`,
            },
          ],
        };

        // console.log(state.usedInputObjects);

        return [struct, protocol, ...enumDefs];
      },
      ScalarField(node) {
        return {
          kind: 'field',
          fieldName: node.alias,
          typeName: transformScalarType(schema, node.type, state),
        };
      },
      LinkedField(node) {
        const { typeString, baseTypeString } = transformObjectType(
          schema,
          node.type,
          node.alias,
          state
        );
        return {
          kind: 'field',
          fieldName: node.alias,
          typeName: typeString,
          childType: {
            kind: 'readableStruct',
            name: baseTypeString,
            fields: node.selections,
            childTypes: node.selections
              .filter((selection: any) => selection.childType != null)
              .map((selection: any) => selection.childType),
            extends: node.selections
              .filter((selection: any) => selection.protocolName != null)
              .map((selection: any) => selection.protocolName),
          },
        };
      },
      FragmentSpread(node) {
        return {
          kind: 'field',
          fieldName: `fragment_${node.name}`,
          typeName: `FragmentPointer`,
          fragmentName: node.name,
          protocolName: `${node.name}_Key`,
        };
      },
    },
  };
}

function makeTypeNode(node: any, level: number): string {
  switch (node.kind) {
    case 'inputStruct':
      return makeInputStruct(node, level);
    case 'readableStruct':
      return makeReadableStruct(node, level);
    case 'enum':
      return makeReadableEnum(node, level);
    case 'protocol':
      return makeFragmentProtocol(node, level);
    default:
      return '';
  }
}

function makeInputStruct(structType: any, level: number): string {
  if (structType.name.indexOf('.') !== -1) {
    const [parentType, childType] = structType.name.split('.');
    return `${indent(level)}extension ${parentType} {
${makeInputStruct({ ...structType, name: childType }, level + 1)}${indent(
      level
    )}}
`;
  }

  if (!structType.fields.length) {
    return `${indent(level)}typealias ${structType.name} = EmptyVariables\n`;
  }

  let typeText = `${indent(level)}struct ${
    structType.name
  }: VariableDataConvertible {\n`;

  for (const field of structType.fields) {
    if (field.fieldName == null) {
      continue;
    }

    typeText += `${indent(level + 1)}var ${field.fieldName}: ${
      field.typeName
    }\n`;
  }

  typeText += `
${indent(level + 1)}var variableData: VariableData {
${indent(level + 2)}[
`;

  for (const field of structType.fields) {
    if (field.fieldName == null) {
      continue;
    }

    typeText += `${indent(level + 3)}"${field.fieldName}": ${
      field.fieldName
    },\n`;
  }

  typeText += `${indent(level + 2)}]
${indent(level + 1)}}
${indent(level)}}
`;
  return typeText;
}

function makeReadableStruct(structType: any, level: number): string {
  if (structType.name.indexOf('.') !== -1) {
    const [parentType, childType] = structType.name.split('.');
    return `${indent(level)}extension ${parentType} {
${makeReadableStruct({ ...structType, name: childType }, level + 1)}${indent(
      level
    )}}
`;
  }

  const extendsStr = ['Readable', ...structType.extends].join(', ');
  let typeText = `${indent(level)}struct ${structType.name}: ${extendsStr} {\n`;

  for (const field of structType.fields) {
    if (field.fieldName == null) {
      continue;
    }

    typeText += `${indent(level + 1)}var ${field.fieldName}: ${
      field.typeName
    }\n`;
  }

  typeText += `\n${indent(level + 1)}init(from data: SelectorData) {\n`;
  for (const field of structType.fields) {
    if (field.fieldName == null) {
      continue;
    }

    const getExpr =
      field.typeName === 'FragmentPointer'
        ? `fragment: "${field.fragmentName}"`
        : `${field.typeName}.self, "${field.fieldName}"`;
    typeText += `${indent(level + 2)}${
      field.fieldName
    } = data.get(${getExpr})\n`;
  }
  typeText += `${indent(level + 1)}}\n`;

  for (const childType of structType.childTypes) {
    typeText += `\n${makeReadableStruct(childType, level + 1)}`;
  }

  typeText += `${indent(level)}}\n`;
  return typeText;
}

function makeReadableEnum(enumType: any, level: number): string {
  const extendsStr = [
    'String',
    'Hashable',
    'VariableValueConvertible',
    'ReadableScalar',
    'CustomStringConvertible',
  ].join(', ');
  let typeText = `${indent(level)}enum ${enumType.name}: ${extendsStr} {\n`;

  for (const value of enumType.values) {
    typeText += `${indent(
      level + 1
    )}case ${value.toLowerCase()} = "${value}"\n`;
  }

  typeText += `\n${indent(level + 1)}var description: String { rawValue }\n`;

  typeText += `${indent(level)}}\n`;
  return typeText;
}

function makeFragmentProtocol(protocolType: any, level: number): string {
  let typeText = `${indent(level)}protocol ${protocolType.name} {\n`;

  for (const field of protocolType.fields) {
    if (field.fieldName == null) {
      continue;
    }

    typeText += `${indent(level + 1)}var ${field.fieldName}: ${
      field.typeName
    } { get }\n`;
  }

  typeText += `${indent(level)}}\n`;

  const [parentType] = protocolType.alias.split('.');
  typeText += `
${indent(level)}extension ${parentType} {
${indent(level + 1)}func getFragmentPointer(_ key: ${
    protocolType.name
  }) -> FragmentPointer {
${indent(level + 2)}key.${protocolType.fields[0].fieldName}
${indent(level + 1)}}
${indent(level)}}
`;
  return typeText;
}

function transformScalarType(schema: Schema, type: TypeID, state: State) {
  if (schema.isNonNull(type)) {
    return transformNonNullableScalarType(
      schema,
      schema.getNullableType(type),
      state
    );
  } else {
    return `${transformNonNullableScalarType(schema, type, state)}?`;
  }
}

function transformNonNullableScalarType(
  schema: Schema,
  type: TypeID,
  state: State
) {
  if (schema.isList(type)) {
    return `[${transformScalarType(
      schema,
      schema.getListItemType(type),
      state
    )}]`;
  } else if (
    schema.isObject(type) ||
    schema.isUnion(type) ||
    schema.isInterface(type)
  ) {
    return ''; // TODO
  } else if (schema.isScalar(type)) {
    return transformGraphQLScalarType(schema.getTypeString(type), state);
  } else if (schema.isEnum(type)) {
    return transformGraphQLEnumType(schema, schema.assertEnumType(type), state);
  } else {
    throw new Error(`Could not convert from GraphQL type ${String(type)}`);
  }
}

function transformGraphQLScalarType(
  typeName: string,
  options: TypeGeneratorOptions
) {
  const customType = options.customScalars[typeName];

  switch (customType ?? typeName) {
    case 'ID':
    case 'String':
      return `String`;
    case 'Int':
      return `Int`;
    case 'Float':
      return `Double`;
    case 'Boolean':
      return `Bool`;
    default:
      return customType == null ? `Any` : customType;
  }
}

function transformGraphQLEnumType(schema: Schema, type: TypeID, state: State) {
  state.usedEnums[schema.getTypeString(type)] = type;
  return schema.getTypeString(schema.getTypeString(type));
}

function transformObjectType(
  schema: Schema,
  type: TypeID,
  alias: string,
  state: State
) {
  if (schema.isNonNull(type)) {
    return transformNonNullableObjectType(
      schema,
      schema.getNullableType(type),
      alias,
      state
    );
  } else {
    const { typeString, baseTypeString } = transformNonNullableObjectType(
      schema,
      type,
      alias,
      state
    );
    return { typeString: `${typeString}?`, baseTypeString };
  }
}

function transformNonNullableObjectType(
  schema: Schema,
  type: TypeID,
  alias: string,
  state: State
): { typeString: string; baseTypeString: string } {
  if (schema.isList(type)) {
    const { typeString, baseTypeString } = transformObjectType(
      schema,
      schema.getListItemType(type),
      alias,
      state
    );
    return { typeString: `[${typeString}]`, baseTypeString };
  } else if (schema.isObject(type)) {
    const typeString = `${schema.getTypeString(type)}_${alias}`;
    return {
      typeString,
      baseTypeString: typeString,
    };
  } else {
    throw new Error(`Could not convert from GraphQL type ${String(type)}`);
  }
}

function transformInputType(schema: Schema, type: TypeID, state: State) {
  if (schema.isNonNull(type)) {
    return transformNonNullableInputType(
      schema,
      schema.getNullableType(type),
      state
    );
  } else {
    return `${transformNonNullableInputType(schema, type, state)}?`;
  }
}

function transformNonNullableInputType(
  schema: Schema,
  type: TypeID,
  state: State
) {
  if (schema.isList(type)) {
    return `[${transformInputType(
      schema,
      schema.getListItemType(type),
      state
    )}]`;
  } else if (schema.isScalar(type)) {
    return transformGraphQLScalarType(schema.getTypeString(type), state);
  } else if (schema.isEnum(type)) {
    return transformGraphQLEnumType(schema, schema.assertEnumType(type), state);
  } else if (schema.isInputObject(type)) {
    return transformGraphQLInputObjectType(
      schema,
      schema.assertInputObjectType(type),
      state
    );
  } else if (schema.isEnum(type)) {
    return transformGraphQLEnumType(schema, schema.assertEnumType(type), state);
  }
}

function transformGraphQLInputObjectType(
  schema: Schema,
  type: TypeID,
  state: State
) {
  const typeIdentifier = schema.getTypeString(type);
  if (state.generatedInputObjects[typeIdentifier]) {
    return typeIdentifier;
  }

  // we call into this recursively, so this prevents us from visiting the same type twice
  state.generatedInputObjects[typeIdentifier] = 'pending';

  const typeFields = schema.getFields(schema.assertInputObjectType(type));
  const fields = typeFields.map(fieldID => {
    const fieldType = schema.getFieldType(fieldID);
    const fieldName = schema.getFieldName(fieldID);
    return {
      kind: 'field',
      fieldName,
      typeName: transformInputType(schema, fieldType, state),
    };
  });

  const struct = {
    kind: 'inputStruct',
    name: typeIdentifier,
    fields,
  };

  state.generatedInputObjects[typeIdentifier] = struct;
  return typeIdentifier;
}

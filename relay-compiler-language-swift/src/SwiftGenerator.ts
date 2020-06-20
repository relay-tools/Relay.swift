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
        let typeKind = 'readableStruct';

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

        const struct = {
          kind: typeKind,
          name: `${node.name}.Data`,
          originalTypeName: schema.getTypeString(node.type),
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
        const {
          typeString,
          baseTypeString,
          originalTypeName,
          kind,
        } = transformObjectType(schema, node.type, node.alias, state);

        let childTypeKind = 'readableStruct';

        // Only generate an enum here if there are actually inline fragments in the selections.
        // If the type is a union or interface but only contains fragment spreads or fields from
        // the interface, then we should represent it as a struct.
        if (
          node.selections.some((field: any) => field.kind === 'inlineFragment')
        ) {
          if (kind === 'Union') {
            childTypeKind = 'readableUnion';
          } else if (kind === 'Interface') {
            childTypeKind = 'readableInterface';
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
      InlineFragment(node) {
        const { baseTypeString } = transformObjectType(
          schema,
          node.typeCondition,
          '',
          state
        );
        return {
          kind: 'inlineFragment',
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
    },
  };
}

function makeTypeNode(node: any, level: number): string {
  switch (node.kind) {
    case 'inputStruct':
      return makeInputStruct(node, level);
    case 'readableStruct':
      return makeReadableStruct(node, level);
    case 'readableUnion':
      return makeReadableUnion(node, level);
    case 'readableInterface':
      return makeReadableInterface(node, level);
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

  const extendsStr = ['Decodable', ...structType.extends].join(', ');
  let typeText = `${indent(level)}struct ${structType.name}: ${extendsStr} {\n`;

  for (const field of structType.fields) {
    if (field.fieldName == null) {
      continue;
    }

    typeText += `${indent(level + 1)}var ${field.fieldName}: ${
      field.typeName
    }\n`;
  }

  for (const childType of structType.childTypes) {
    typeText += `\n${makeTypeNode(childType, level + 1)}`;
  }

  typeText += `${indent(level)}}\n`;
  return typeText;
}

function makeReadableUnion(unionType: any, level: number): string {
  if (unionType.name.indexOf('.') !== -1) {
    const [parentType, childType] = unionType.name.split('.');
    return `${indent(level)}extension ${parentType} {
${makeReadableUnion({ ...unionType, name: childType }, level + 1)}${indent(
      level
    )}}
`;
  }

  const extendsStr = ['Decodable', ...unionType.extends].join(', ');
  let typeText = `${indent(level)}enum ${unionType.name}: ${extendsStr} {\n`;

  for (const field of unionType.fields) {
    if (field.kind !== 'inlineFragment') {
      if (field.typeName !== 'FragmentPointer') {
        throw new Error(
          `Unexpected field kind '${field.kind}' in union type ${unionType.name}`
        );
      } else {
        continue;
      }
    }

    typeText += `${indent(level + 1)}case ${enumTypeCaseName(
      field.childType.name
    )}(${field.childType.name})\n`;
  }

  typeText += `${indent(level + 1)}case unknown

${indent(level + 1)}private enum TypeKeys: String, CodingKey {
${indent(level + 2)}case __typename  
${indent(level + 1)}}
  
${indent(level + 1)}init(from decoder: Decoder) throws {
${indent(
  level + 2
)}let container = try decoder.container(keyedBy: TypeKeys.self)
${indent(
  level + 2
)}let typeName = try container.decode(String.self, forKey: .__typename)
${indent(level + 2)}switch typeName {
`;

  for (const field of unionType.fields) {
    if (field.kind !== 'inlineFragment') {
      continue;
    }

    typeText += `${indent(level + 2)}case "${field.childType.name}":
${indent(level + 3)}self = .${enumTypeCaseName(field.childType.name)}(try ${
      field.childType.name
    }(from: decoder))
`;
  }

  typeText += `${indent(level + 2)}default:
${indent(level + 3)}self = .unknown
${indent(level + 2)}}
${indent(level + 1)}}
`;

  for (const field of unionType.fields) {
    if (field.kind !== 'inlineFragment') {
      continue;
    }

    typeText += `
${indent(level + 1)}var as${field.childType.name}: ${field.childType.name}? {
${indent(level + 2)}if case .${enumTypeCaseName(
      field.childType.name
    )}(let val) = self {
${indent(level + 3)}return val
${indent(level + 2)}}
${indent(level + 2)}return nil
${indent(level + 1)}}
`;
  }

  const otherTypeFields = unionType.fields.filter(
    field => field.kind === 'field'
  );
  const otherChildTypes = otherTypeFields
    .filter((selection: any) => selection.childType != null)
    .map((selection: any) => selection.childType);
  const otherExtends = otherTypeFields
    .filter((selection: any) => selection.protocolName != null)
    .map((selection: any) => selection.protocolName);

  for (const field of otherTypeFields) {
    typeText += `\n${indent(level + 1)}var ${field.fieldName}: ${
      field.typeName
    } {
${indent(level + 2)}switch self {
`;

    for (const childType of unionType.childTypes) {
      typeText += `${indent(level + 2)}case .${enumTypeCaseName(
        childType.name
      )}(let val):
${indent(level + 3)}return val.${field.fieldName}
`;
    }

    typeText += `${indent(level + 2)}default:
${indent(level + 3)}preconditionFailure("Trying to access field '${
      field.fieldName
    }' from unknown union member")
${indent(level + 2)}}
${indent(level + 1)}}
`;
  }

  for (const childType of unionType.childTypes) {
    typeText += `\n${makeTypeNode(
      {
        ...childType,
        fields: [...otherTypeFields, ...childType.fields],
        childTypes: [...otherChildTypes, ...childType.childTypes],
        extends: [...otherExtends, ...childType.extends],
      },
      level + 1
    )}`;
  }

  typeText += `${indent(level)}}\n`;
  return typeText;
}

function makeReadableInterface(interfaceType: any, level: number): string {
  if (interfaceType.name.indexOf('.') !== -1) {
    const [parentType, childType] = interfaceType.name.split('.');
    return `${indent(level)}extension ${parentType} {
${makeReadableInterface(
  { ...interfaceType, name: childType },
  level + 1
)}${indent(level)}}
`;
  }

  const extendsStr = ['Decodable', ...interfaceType.extends].join(', ');
  let typeText = `${indent(level)}enum ${
    interfaceType.name
  }: ${extendsStr} {\n`;

  for (const field of interfaceType.fields) {
    if (field.kind !== 'inlineFragment') {
      continue;
    }

    typeText += `${indent(level + 1)}case ${enumTypeCaseName(
      field.childType.name
    )}(${field.childType.name})\n`;
  }

  typeText += `${indent(level + 1)}case ${enumTypeCaseName(
    interfaceType.originalTypeName
  )}(${interfaceType.originalTypeName})

${indent(level + 1)}private enum TypeKeys: String, CodingKey {
${indent(level + 2)}case __typename  
${indent(level + 1)}}
  
${indent(level + 1)}init(from decoder: Decoder) throws {
${indent(
  level + 2
)}let container = try decoder.container(keyedBy: TypeKeys.self)
${indent(
  level + 2
)}let typeName = try container.decode(String.self, forKey: .__typename)
${indent(level + 2)}switch typeName {
`;

  for (const field of interfaceType.fields) {
    if (field.kind !== 'inlineFragment') {
      continue;
    }

    typeText += `${indent(level + 2)}case "${field.childType.name}":
${indent(level + 3)}self = .${enumTypeCaseName(field.childType.name)}(try ${
      field.childType.name
    }(from: decoder))
`;
  }

  typeText += `${indent(level + 2)}default:
${indent(level + 3)}self = .${enumTypeCaseName(
    interfaceType.originalTypeName
  )}(try ${interfaceType.originalTypeName}(from: decoder))
${indent(level + 2)}}
${indent(level + 1)}}
`;

  const otherTypeFields = interfaceType.fields.filter(
    field => field.kind === 'field'
  );
  const otherChildTypes = otherTypeFields
    .filter((selection: any) => selection.childType != null)
    .map((selection: any) => selection.childType);
  const otherExtends = otherTypeFields
    .filter((selection: any) => selection.protocolName != null)
    .map((selection: any) => selection.protocolName);

  const childTypes = [
    ...interfaceType.childTypes,
    {
      kind: 'readableStruct',
      name: interfaceType.originalTypeName,
      fields: [],
      childTypes: [],
      extends: [],
    },
  ];

  for (const childType of childTypes) {
    typeText += `
${indent(level + 1)}var as${childType.name}: ${childType.name}? {
${indent(level + 2)}if case .${enumTypeCaseName(
      childType.name
    )}(let val) = self {
${indent(level + 3)}return val
${indent(level + 2)}}
${indent(level + 2)}return nil
${indent(level + 1)}}
`;
  }

  for (const childType of childTypes) {
    typeText += `\n${makeTypeNode(
      {
        ...childType,
        fields: [...otherTypeFields, ...childType.fields],
        childTypes: [...otherChildTypes, ...childType.childTypes],
        extends: [...otherExtends, ...childType.extends],
      },
      level + 1
    )}`;
  }

  typeText += `${indent(level)}}\n`;
  return typeText;
}

function enumTypeCaseName(typeName: string): string {
  return typeName.replace(/^[A-Z]+/, s => s.toLowerCase());
}

function makeReadableEnum(enumType: any, level: number): string {
  const extendsStr = [
    'String',
    'Decodable',
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

interface TransformedObjectType {
  kind: 'Object' | 'Union' | 'Interface';
  typeString: string;
  baseTypeString: string;
  originalTypeName: string;
}

function transformObjectType(
  schema: Schema,
  type: TypeID,
  alias: string,
  state: State
): TransformedObjectType {
  if (schema.isNonNull(type)) {
    return transformNonNullableObjectType(
      schema,
      schema.getNullableType(type),
      alias,
      state
    );
  } else {
    const { typeString, ...rest } = transformNonNullableObjectType(
      schema,
      type,
      alias,
      state
    );
    return { typeString: `${typeString}?`, ...rest };
  }
}

function transformNonNullableObjectType(
  schema: Schema,
  type: TypeID,
  alias: string,
  state: State
): TransformedObjectType {
  if (schema.isList(type)) {
    const { typeString, ...rest } = transformObjectType(
      schema,
      schema.getListItemType(type),
      alias,
      state
    );
    return { typeString: `[${typeString}]`, ...rest };
  } else if (
    schema.isObject(type) ||
    schema.isUnion(type) ||
    schema.isInterface(type)
  ) {
    let kind: TransformedObjectType['kind'];
    if (schema.isObject(type)) {
      kind = 'Object';
    } else if (schema.isUnion(type)) {
      kind = 'Union';
    } else if (schema.isInterface(type)) {
      kind = 'Interface';
    } else {
      throw new Error('Unexpected type');
    }
    let typeString = schema.getTypeString(type);
    if (alias) {
      typeString = `${typeString}_${alias}`;
    }
    return {
      typeString,
      baseTypeString: typeString,
      originalTypeName: schema.getTypeString(type),
      kind,
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

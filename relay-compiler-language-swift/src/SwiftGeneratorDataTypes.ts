import { indent } from './util';

export type TypeNode =
  | InputStructNode
  | ReadableStructNode
  | ReadableUnionNode
  | ReadableInterfaceNode
  | EnumNode
  | ProtocolNode;

export type ReadableTypeNode =
  | ReadableStructNode
  | ReadableUnionNode
  | ReadableInterfaceNode;

export interface FieldNode {
  kind: 'field';
  fieldName: string;
  typeName: string;
  fragmentName?: string;
  protocolName?: string;
  childType?: ReadableTypeNode;
}

export interface InlineFragmentNode {
  kind: 'inlineFragment';
  childType: TypeNode;
}

export interface InputStructNode {
  kind: 'inputStruct';
  name: string;
  fields: FieldNode[];
  isRootVariables?: boolean;
}

interface ReadableNode {
  name: string;
  originalTypeName?: string;
  childTypes: ReadableTypeNode[];
  extends: string[];
}

export interface ReadableStructNode extends ReadableNode {
  kind: 'readableStruct';
  fields: FieldNode[];
}

export interface ReadableUnionNode extends ReadableNode {
  kind: 'readableUnion';
  fields: (FieldNode | InlineFragmentNode)[];
}

export interface ReadableInterfaceNode extends ReadableNode {
  kind: 'readableInterface';
  fields: (FieldNode | InlineFragmentNode)[];
}

export interface EnumNode {
  kind: 'enum';
  name: string;
  values: string[];
}

export interface ProtocolNode {
  kind: 'protocol';
  name: string;
  alias: string;
  fields: FieldNode[];
}

export function makeTypeNode(node: TypeNode, level: number): string {
  switch (node.kind) {
    case 'inputStruct':
      return makeInputStruct(node, level);
    case 'readableStruct':
      return makeReadableStruct(node, level);
    case 'readableUnion':
    case 'readableInterface':
      return makeReadableUnionOrInterface(node, level);
    case 'enum':
      return makeReadableEnum(node, level);
    case 'protocol':
      return makeFragmentProtocol(node, level);
  }
}

function makeInputStruct(structType: InputStructNode, level: number): string {
  if (structType.name.indexOf('.') !== -1) {
    const [parentType, childType] = structType.name.split('.');
    let text = `${indent(level)}extension ${parentType} {
${makeInputStruct({ ...structType, name: childType }, level + 1)}${indent(
      level
    )}}
`;

    if (structType.isRootVariables) {
      text += `
#if canImport(RelaySwiftUI)

import RelaySwiftUI

@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
extension RelaySwiftUI.QueryNext.WrappedValue where O == ${parentType} {
${indent(1)}func get(${structType.fields
        .map(
          field =>
            `${field.fieldName}: ${field.typeName}${
              field.typeName.endsWith('?') ? ' = nil' : ''
            }`
        )
        .join(', ')}) -> RelaySwiftUI.QueryNext<${parentType}>.Result {
${indent(2)}self.get(.init(${structType.fields
        .map(field => `${field.fieldName}: ${field.fieldName}`)
        .join(', ')}))
${indent(1)}}
}

#endif
`;
    }

    return text;
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

  if (structType.isRootVariables === true) {
    typeText += `
${indent(level)}init(`;
    typeText += structType.fields
      .map(
        field =>
          `${field.fieldName}: ${field.typeName}${
            field.typeName.endsWith('?') ? ' = nil' : ''
          }`
      )
      .join(', ');
    typeText += `) {
${indent(level + 1)}self.init(variables: .init(${structType.fields
      .map(field => `${field.fieldName}: ${field.fieldName}`)
      .join(', ')}))
${indent(level)}}
`;
  }
  return typeText;
}

function makeReadableStruct(
  structType: ReadableStructNode,
  level: number
): string {
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

function makeReadableUnionOrInterface(
  interfaceType: ReadableUnionNode | ReadableInterfaceNode,
  level: number
): string {
  if (interfaceType.name.indexOf('.') !== -1) {
    const [parentType, childType] = interfaceType.name.split('.');
    return `${indent(level)}extension ${parentType} {
${makeReadableUnionOrInterface(
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
    (field): field is FieldNode => field.kind === 'field'
  );
  const otherChildTypes = otherTypeFields
    .filter(selection => selection.childType != null)
    .map(selection => selection.childType!);
  const otherExtends = otherTypeFields
    .filter(selection => selection.protocolName != null)
    .map(selection => selection.protocolName!);

  const childTypes: ReadableTypeNode[] = [
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

  for (const field of otherTypeFields) {
    typeText += `\n${indent(level + 1)}var ${field.fieldName}: ${
      field.typeName
    } {
${indent(level + 2)}switch self {
`;

    for (const childType of childTypes) {
      typeText += `${indent(level + 2)}case .${enumTypeCaseName(
        childType.name
      )}(let val):
${indent(level + 3)}return val.${field.fieldName}
`;
    }

    typeText += `${indent(level + 2)}}
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
      } as TypeNode,
      level + 1
    )}`;
  }

  typeText += `${indent(level)}}\n`;
  return typeText;
}

function enumTypeCaseName(typeName: string): string {
  return typeName.replace(/^[A-Z]+/, s => s.toLowerCase());
}

function makeReadableEnum(enumType: EnumNode, level: number): string {
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

function makeFragmentProtocol(
  protocolType: ProtocolNode,
  level: number
): string {
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

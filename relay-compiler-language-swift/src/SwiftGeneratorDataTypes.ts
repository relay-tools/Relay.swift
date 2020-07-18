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

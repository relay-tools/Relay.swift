/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import {
  ReadableStructNode,
  TypeNode,
  ReadableUnionNode,
  ReadableInterfaceNode,
  InlineFragmentNode,
  FieldNode,
  ReadableTypeNode,
} from '../SwiftGeneratorDataTypes';
import { ReadableEnum } from './ReadableEnum';
import { InputType } from './InputType';
import { FragmentProtocol } from './FragmentProtocol';

export const DataType = ({ node }: { node: TypeNode }) => {
  switch (node.kind) {
    case 'inputStruct':
      return <InputType node={node} />;
    case 'readableStruct':
      return <ReadableStruct node={node} />;
    case 'readableUnion':
    case 'readableInterface':
      return <ReadableUnionOrInterface node={node} />;
    case 'enum':
      return <ReadableEnum node={node} />;
    case 'protocol':
      return <FragmentProtocol node={node} />;
  }
};

const ReadableStruct = ({ node }: { node: ReadableStructNode }) => {
  if (node.name.indexOf('.') !== -1) {
    const [parentType, childType] = node.name.split('.');

    return (
      <extension name={parentType}>
        <ReadableStruct node={{ ...node, name: childType }} />
      </extension>
    );
  }

  const inherit = ['Decodable', ...node.extends];

  return (
    <struct name={node.name} inherit={inherit}>
      {node.fields.map(field =>
        field.fieldName == null ? null : (
          <var name={field.fieldName} type={field.typeName} />
        )
      )}
      {node.childTypes.map(childType => (
        <DataType node={childType} />
      ))}
    </struct>
  );
};

const ReadableUnionOrInterface = ({
  node,
}: {
  node: ReadableUnionNode | ReadableInterfaceNode;
}) => {
  if (node.name.indexOf('.') !== -1) {
    const [parentType, childType] = node.name.split('.');

    return (
      <extension name={parentType}>
        <ReadableUnionOrInterface node={{ ...node, name: childType }} />
      </extension>
    );
  }

  const inlineFragmentFields = node.fields.filter(
    (field): field is InlineFragmentNode => field.kind === 'inlineFragment'
  );
  const otherTypeFields = node.fields.filter(
    (field): field is FieldNode => field.kind === 'field'
  );
  const otherChildTypes = otherTypeFields
    .filter(selection => selection.childType != null)
    .map(selection => selection.childType!);
  const otherExtends = otherTypeFields
    .filter(selection => selection.protocolName != null)
    .map(selection => selection.protocolName!);

  const childTypes: ReadableTypeNode[] = [
    ...node.childTypes,
    {
      kind: 'readableStruct',
      name: node.originalTypeName,
      fields: [],
      childTypes: [],
      extends: [],
    },
  ];

  return (
    <enum name={node.name} inherit={['Decodable', ...node.extends]}>
      {inlineFragmentFields.map(field => (
        <case
          name={enumTypeCaseName(field.childType.name)}
          parameters={[field.childType.name]}
        />
      ))}
      <case
        name={enumTypeCaseName(node.originalTypeName)}
        parameters={[node.originalTypeName]}
      />
      <enum access="private" name="TypeKeys" inherit={['String', 'CodingKey']}>
        <case name="__typename" />
      </enum>
      <UnionOrInterfaceInitializer
        node={node}
        inlineFragmentFields={inlineFragmentFields}
      />
      {childTypes.map(childType => (
        <AsChildTypeProperty node={childType} />
      ))}
      {otherTypeFields.map(field => (
        <CommonFieldProperty field={field} childTypes={childTypes} />
      ))}
      {childTypes.map(childType => (
        <DataType
          node={
            {
              ...childType,
              fields: [...otherTypeFields, ...childType.fields],
              childTypes: [...otherChildTypes, ...childType.childTypes],
              extends: [...otherExtends, ...childType.extends],
            } as TypeNode
          }
        />
      ))}
    </enum>
  );
};

const UnionOrInterfaceInitializer = ({
  node,
  inlineFragmentFields,
}: {
  node: ReadableUnionNode | ReadableInterfaceNode;
  inlineFragmentFields: readonly InlineFragmentNode[];
}) => {
  return (
    <init
      parameters={[<paramdecl label="from" name="decoder" type="Decoder" />]}
      throws
    >
      {'let container = try decoder.container(keyedBy: TypeKeys.self)'}
      {'let typeName = try container.decode(String.self, forKey: .__typename)'}
      <switch value="typeName">
        {inlineFragmentFields.map(field => (
          <case name={<literal string={field.childType.name} />}>
            {`self = .${enumTypeCaseName(field.childType.name)}(try ${
              field.childType.name
            }(from: decoder))`}
          </case>
        ))}
        <case isDefault>
          {`self = .${enumTypeCaseName(node.originalTypeName)}(try ${
            node.originalTypeName
          }(from: decoder))`}
        </case>
      </switch>
    </init>
  );
};

const AsChildTypeProperty = ({ node }: { node: TypeNode }) => {
  return (
    <var name={`as${node.name}`} type={`${node.name}?`}>
      {`if case .${enumTypeCaseName(node.name)}(let val) = self {`}
      {'    return val'}
      {'}'}
      {'return nil'}
    </var>
  );
};

const CommonFieldProperty = ({
  field,
  childTypes,
}: {
  field: FieldNode;
  childTypes: readonly TypeNode[];
}) => {
  return (
    <var name={field.fieldName} type={field.typeName}>
      <switch value="self">
        {childTypes.map(childType => (
          <case name={`.${enumTypeCaseName(childType.name)}(let val)`}>
            {`return val.${field.fieldName}`}
          </case>
        ))}
      </switch>
    </var>
  );
};

function enumTypeCaseName(typeName: string): string {
  return typeName.replace(/^[A-Z]+/, s => s.toLowerCase());
}

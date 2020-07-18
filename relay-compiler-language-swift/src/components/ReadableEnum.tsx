import { EnumNode } from '../SwiftGeneratorDataTypes';
/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';

export const ReadableEnum = ({ node }: { node: EnumNode }) => {
  return (
    <enum
      name={node.name}
      inherit={[
        'String',
        'Decodable',
        'Hashable',
        'VariableValueConvertible',
        'ReadableScalar',
        'CustomStringConvertible',
      ]}
    >
      {node.values.map(value => (
        <case name={value.toLowerCase()}>
          <literal string={value} />
        </case>
      ))}
      <var name="description" type="String">
        rawValue
      </var>
    </enum>
  );
};

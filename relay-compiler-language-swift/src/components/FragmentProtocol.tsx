/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ProtocolNode } from '../SwiftGeneratorDataTypes';

export const FragmentProtocol = ({ node }: { node: ProtocolNode }) => {
  return (
    <protocol name={node.name}>
      {node.fields.map(field =>
        field.fieldName == null ? null : (
          <var name={field.fieldName} type={field.typeName} />
        )
      )}
    </protocol>
  );
};

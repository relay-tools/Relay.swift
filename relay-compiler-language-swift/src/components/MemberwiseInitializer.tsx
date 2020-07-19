/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { FieldNode } from '../SwiftGeneratorDataTypes';

export const MemberwiseInitializer = ({
  fields,
}: {
  fields: readonly FieldNode[];
}) => {
  return (
    <init
      parameters={fields.map(field => (
        <paramdecl
          name={field.fieldName}
          type={field.typeName}
          defaultValue={field.typeName.endsWith('?') ? 'nil' : null}
        />
      ))}
    >
      {fields.map(field => `self.${field.fieldName} = ${field.fieldName}`)}
    </init>
  );
};

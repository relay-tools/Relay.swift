/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ReaderArgument, NormalizationArgument } from 'relay-runtime';
import { ValueLiteral } from './ValueLiteral';

export const ArgumentsExpr = ({
  args,
}: {
  args: readonly ReaderArgument[] | readonly NormalizationArgument[];
}) => {
  return (
    <literal
      expanded
      array={(args as any).map(arg => {
        switch (arg.kind) {
          case 'Literal':
            return (
              <call
                name="LiteralArgument"
                parameters={[
                  <param label="name">
                    <literal string={arg.name} />
                  </param>,
                  <param label="value">
                    <ValueLiteral value={arg.value} />
                  </param>,
                ]}
              />
            );
          case 'Variable':
            return (
              <call
                name="VariableArgument"
                parameters={[
                  <param label="name">
                    <literal string={arg.name} />
                  </param>,
                  <param label="variableName">
                    <literal string={arg.variableName} />
                  </param>,
                ]}
              />
            );
          case 'ListValue':
            return (
              <call
                name="ListValueArgument"
                parameters={[
                  <param label="name">
                    <literal string={arg.name} />
                  </param>,
                  <param label="items">
                    <ArgumentsExpr args={arg.items} />
                  </param>,
                ]}
              />
            );
          case 'ObjectValue':
            return (
              <call
                name="ObjectValueArgument"
                parameters={[
                  <param label="name">
                    <literal string={arg.name} />
                  </param>,
                  <param label="fields">
                    <ArgumentsExpr args={arg.fields} />
                  </param>,
                ]}
              />
            );
        }
      })}
    />
  );
};

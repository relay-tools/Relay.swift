/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';

export const ConnectionVariableConfig = ({ count, cursor }) => {
  return (
    <call
      name="ConnectionVariableConfig"
      parameters={[
        <param label="count">
          <literal string={count} />
        </param>,
        <param label="cursor">
          <literal string={cursor} />
        </param>,
      ]}
    />
  );
};

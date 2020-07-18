/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { RequestParameters } from 'relay-runtime';

export const RequestParametersExpr = ({
  params,
}: {
  params: RequestParameters;
}) => {
  return (
    <call
      name="RequestParameters"
      parameters={[
        <param label="name">
          <literal string={params.name} />
        </param>,
        <param label="operationKind">
          {`.${params.operationKind.toLowerCase()}`}
        </param>,
        <param label="text">{`"""
${params.text}"""`}</param>,
      ]}
      expanded
    />
  );
};

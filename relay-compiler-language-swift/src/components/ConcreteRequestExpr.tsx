/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ConcreteRequest } from 'relay-runtime';
import { ReaderFragmentExpr } from './ReaderFragmentExpr';
import { NormalizationOperationExpr } from './NormalizationOperationExpr';
import { RequestParametersExpr } from './RequestParametersExpr';

export const ConcreteRequestExpr = ({ node }: { node: ConcreteRequest }) => {
  return (
    <call
      name="ConcreteRequest"
      parameters={[
        <param label="fragment">
          <ReaderFragmentExpr node={node.fragment} />
        </param>,
        <param label="operation">
          <NormalizationOperationExpr node={node.operation} />
        </param>,
        <param label="params">
          <RequestParametersExpr params={node.params} />
        </param>,
      ]}
      expanded
    />
  );
};

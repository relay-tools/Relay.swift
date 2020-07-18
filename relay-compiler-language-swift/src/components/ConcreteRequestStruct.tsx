/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ConcreteRequest } from 'relay-runtime';
import { ConcreteRequestExpr } from './ConcreteRequestExpr';

export const ConcreteRequestStruct = ({ node }: { node: ConcreteRequest }) => {
  return (
    <struct name={node.operation.name}>
      <var name="variables" type="Variables" />
      <init parameters={[<paramdecl name="variables" type="Variables" />]}>
        self.variables = variables
      </init>
      <var isStatic name="node" type="ConcreteRequest">
        <ConcreteRequestExpr node={node} />
      </var>
    </struct>
  );
};

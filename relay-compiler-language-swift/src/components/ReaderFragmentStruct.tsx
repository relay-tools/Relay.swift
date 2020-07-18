/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ReaderFragment } from 'relay-runtime';
import { ReaderFragmentExpr } from './ReaderFragmentExpr';

export const ReaderFragmentStruct = ({ node }: { node: ReaderFragment }) => {
  return (
    <struct name={node.name}>
      <var name="fragmentPointer" type="FragmentPointer" />
      <init parameters={[<paramdecl name="key" type={`${node.name}_Key`} />]}>
        {`fragmentPointer = key.fragment_${node.name}`}
      </init>
      <var isStatic name="node" type="ReaderFragment">
        <ReaderFragmentExpr node={node} />
      </var>
    </struct>
  );
};

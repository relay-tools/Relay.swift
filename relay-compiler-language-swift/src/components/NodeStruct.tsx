/** @jsx swiftJSX */

import { swiftJSX, Fragment } from '../swiftJSX';
import { GeneratedNode, ConcreteRequest, ReaderFragment } from 'relay-runtime';
import { ConcreteRequestStruct } from './ConcreteRequestStruct';
import { ReaderFragmentStruct } from './ReaderFragmentStruct';
import { RefetchFragmentExtension } from './RefetchFragmentExtension';
import { SwiftUIFragmentExtension } from './SwiftUIFragmentExtension';

export const NodeStruct = ({
  node,
  typeText,
}: {
  node: GeneratedNode;
  typeText: string;
}) => {
  switch (node.kind) {
    case 'Request':
      const request = node as ConcreteRequest;
      return (
        <Fragment>
          <ConcreteRequestStruct node={request} />
          {typeText}
          <extension
            name={request.operation.name}
            inherit={['Relay.Operation']}
          />
        </Fragment>
      );
    case 'Fragment':
      const fragment = node as ReaderFragment;
      return (
        <Fragment>
          <ReaderFragmentStruct node={fragment} />
          {typeText}
          <extension name={fragment.name} inherit={['Relay.Fragment']} />
          {fragment.metadata?.refetch && (
            <RefetchFragmentExtension node={fragment} />
          )}
          <SwiftUIFragmentExtension node={fragment} />
        </Fragment>
      );
  }
};

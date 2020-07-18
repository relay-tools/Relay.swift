/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ReaderFragment } from 'relay-runtime';
import { RefetchMetadata } from './RefetchMetadata';

export const RefetchFragmentExtension = ({
  node,
}: {
  node: ReaderFragment;
}) => {
  const refetch = node.metadata.refetch;
  const operationName = (refetch.operation as string)
    .replace('@@MODULE_START@@', '')
    .replace('.graphql@@MODULE_END@@', '');

  return (
    <extension
      name={node.name}
      inherit={[
        refetch.connection
          ? 'Relay.PaginationFragment'
          : 'Relay.RefetchFragment',
      ]}
    >
      <typealias name="Operation">{operationName}</typealias>
      <var isStatic name="metadata" type="Metadata">
        <RefetchMetadata metadata={refetch} />
      </var>
    </extension>
  );
};

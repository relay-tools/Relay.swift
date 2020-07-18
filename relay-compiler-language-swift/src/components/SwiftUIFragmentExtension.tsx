/** @jsx swiftJSX */

import { swiftJSX, Fragment } from '../swiftJSX';
import { ReaderFragment } from 'relay-runtime';
import { SwiftUICheck } from './SwiftUICheck';
import { AvailableOnNewPlatforms } from './AvailableOnNewPlatforms';

export const SwiftUIFragmentExtension = ({
  node,
}: {
  node: ReaderFragment;
}) => {
  return (
    <SwiftUICheck>
      <import module="RelaySwiftUI" />
      <extension name={`${node.name}_Key`}>
        <AsFragmentFunction fragmentName={node.name} type="FragmentNext" />
        {node.metadata?.refetch ? (
          <Fragment>
            <AsFragmentFunction
              fragmentName={node.name}
              type="RefetchableFragment"
            />
            {node.metadata.refetch.connection ? (
              <AsFragmentFunction
                fragmentName={node.name}
                type="PaginationFragmentNext"
              />
            ) : null}
          </Fragment>
        ) : null}
      </extension>
    </SwiftUICheck>
  );
};

const AsFragmentFunction = ({
  fragmentName,
  type,
}: {
  fragmentName: string;
  type: string;
}) => {
  return (
    <AvailableOnNewPlatforms>
      <function
        name="asFragment"
        returns={`RelaySwiftUI.${type}<${fragmentName}>`}
      >
        {`RelaySwiftUI.${type}<${fragmentName}>(self)`}
      </function>
    </AvailableOnNewPlatforms>
  );
};

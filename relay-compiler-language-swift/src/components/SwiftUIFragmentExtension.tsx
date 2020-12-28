/** @jsx swiftJSX */

import { swiftJSX, DeclarationGroup } from '../swiftJSX';
import { ReaderFragment } from 'relay-runtime';
import { SwiftUICheck } from './SwiftUICheck';

export const SwiftUIFragmentExtension = ({
  node,
}: {
  node: ReaderFragment;
}) => {
  return (
    <SwiftUICheck>
      <DeclarationGroup>
        <import module="RelaySwiftUI" />
        <extension name={`${node.name}_Key`}>
          <DeclarationGroup>
            <AsFragmentFunction fragmentName={node.name} type="Fragment" />
            {node.metadata?.refetch ? (
              <DeclarationGroup>
                <AsFragmentFunction
                  fragmentName={node.name}
                  type="RefetchableFragment"
                />
                {node.metadata.refetch.connection ? (
                  <AsFragmentFunction
                    fragmentName={node.name}
                    type="PaginationFragment"
                  />
                ) : null}
              </DeclarationGroup>
            ) : null}
          </DeclarationGroup>
        </extension>
      </DeclarationGroup>
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
    <function
      name="asFragment"
      returns={`RelaySwiftUI.${type}<${fragmentName}>`}
    >
      {`RelaySwiftUI.${type}<${fragmentName}>(self)`}
    </function>
  );
};

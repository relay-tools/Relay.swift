/** @jsx swiftJSX */

import { swiftJSX, renderSwift } from '../../src/swiftJSX';
import { ReaderFragment } from 'relay-runtime';
import { RefetchFragmentExtension } from '../../src/components/RefetchFragmentExtension';

test('refetchable fragment', () => {
  const node: ReaderFragment = {
    kind: 'Fragment',
    name: 'TweetDetail_tweet',
    type: 'TweetGroup',
    metadata: {
      refetch: {
        fragmentPathInResult: ['node'],
        identifierField: 'id',
        operation:
          '@@MODULE_START@@TweetDetailRefetchQuery.graphql@@MODULE_END@@',
      } as any,
    },
    argumentDefinitions: [],
    selections: [],
  };

  const code = <RefetchFragmentExtension node={node} />;
  expect(renderSwift(code)).toMatchSnapshot();
});

test('pagination fragment', () => {
  const node: ReaderFragment = {
    kind: 'Fragment',
    name: 'TweetList_tweets',
    type: 'Viewer',
    metadata: {
      refetch: {
        fragmentPathInResult: ['viewer'],
        operation:
          '@@MODULE_START@@TweetListPaginationQuery.graphql@@MODULE_END@@',
        connection: {
          path: ['allTweets'],
          forward: { count: 'count', cursor: 'cursor' },
        },
      } as any,
    },
    argumentDefinitions: [],
    selections: [],
  };

  const code = <RefetchFragmentExtension node={node} />;
  expect(renderSwift(code)).toMatchSnapshot();
});

/** @jsx swiftJSX */

import { swiftJSX, renderSwift } from '../../src/swiftJSX';
import { DataType } from '../../src/components/DataTypes';
import {
  ReadableStructNode,
  InputStructNode,
  ProtocolNode,
  EnumNode,
} from '../../src/SwiftGeneratorDataTypes';

test('readable struct', () => {
  const node: ReadableStructNode = {
    kind: 'readableStruct',
    name: 'TweetsList_tweets.Data',
    fields: [
      {
        kind: 'field',
        fieldName: 'allTweets',
        typeName: 'TweetGroupConnection_allTweets',
      },
    ],
    extends: [],
    childTypes: [
      {
        kind: 'readableStruct',
        name: 'TweetGroupConnection_allTweets',
        fields: [
          {
            kind: 'field',
            fieldName: 'edges',
            typeName: '[TweetGroupEdge_edges]',
          },
        ],
        extends: ['ConnectionCollection'],
        childTypes: [
          {
            kind: 'readableStruct',
            name: 'TweetGroupEdge_edges',
            fields: [
              {
                kind: 'field',
                fieldName: 'node',
                typeName: 'TweetGroup_node',
              },
            ],
            extends: ['ConnectionEdge'],
            childTypes: [
              {
                kind: 'readableStruct',
                name: 'TweetGroup_node',
                fields: [
                  {
                    kind: 'field',
                    fieldName: 'id',
                    typeName: 'String',
                  },
                  {
                    kind: 'field',
                    fieldName: 'fragment_TweetRow_tweetGroup',
                    typeName: 'FragmentPointer',
                  },
                ],
                extends: [
                  'Identifiable',
                  'TweetRow_tweetGroup_Key',
                  'ConnectionNode',
                ],
                childTypes: [],
              },
            ],
          },
        ],
      },
    ],
  };

  const code = <DataType node={node} />;
  expect(renderSwift(code)).toMatchSnapshot();
});

test('empty variables type', () => {
  const node: InputStructNode = {
    kind: 'inputStruct',
    name: 'TweetsScreenQuery.Variables',
    fields: [],
    isRootVariables: true,
  };

  const code = <DataType node={node} />;
  expect(renderSwift(code)).toMatchSnapshot();
});

test('simple variables type', () => {
  const node: InputStructNode = {
    kind: 'inputStruct',
    name: 'TweetDetailScreenQuery.Variables',
    fields: [
      {
        kind: 'field',
        fieldName: 'id',
        typeName: 'String',
      },
    ],
    isRootVariables: true,
  };

  const code = <DataType node={node} />;
  expect(renderSwift(code)).toMatchSnapshot();
});

test('fragment protocol', () => {
  const node: ProtocolNode = {
    kind: 'protocol',
    name: 'TweetRow_tweetGroup_Key',
    alias: 'TweetRow_tweetGroup.Key',
    fields: [
      {
        kind: 'field',
        fieldName: 'fragment_TweetRow_tweetGroup',
        typeName: 'FragmentPointer',
      },
    ],
  };

  const code = <DataType node={node} />;
  expect(renderSwift(code)).toMatchSnapshot();
});

test('enum', () => {
  const node: EnumNode = {
    kind: 'enum',
    name: 'TweetFilter',
    values: ['UPCOMING', 'PAST'],
  };

  const code = <DataType node={node} />;
  expect(renderSwift(code)).toMatchSnapshot();
});

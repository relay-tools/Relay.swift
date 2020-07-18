/** @jsx swiftJSX */

import { swiftJSX, renderSwift, Fragment } from '../src/swiftJSX';

test('struct with some vars', () => {
  const code = (
    <struct name="Data">
      <var name="foo" type="String" />
      <var name="bar" type="Int?" />
    </struct>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('struct with a nested struct', () => {
  const code = (
    <struct name="Data" inherit={['Decodable', 'Identifiable']}>
      <var name="tweets" type="[Tweet_tweets]" />
      <var name="id" type="String" />
      <var name="status" type="TweetStatus" />

      <struct name="Tweet_tweets" inherit={['Decodable']}>
        <var name="postedTweetID" type="String?" />
      </struct>
    </struct>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('struct with an initializer', () => {
  const code = (
    <struct name="DetailedTweetRow_tweet">
      <init
        parameters={[
          <paramdecl name="key" type="DetailedTweetRow_tweet_Key" />,
        ]}
      >
        fragmentPointer = key.fragment_DetailedTweetRow_tweet
      </init>
    </struct>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('empty extension', () => {
  const code = (
    <extension name="DetailedTweetRow_tweet" inherit={['Relay.Fragment']} />
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('extension with nested types', () => {
  const code = (
    <extension name="DetailedTweetRow_tweet">
      <struct name="Data" inherit={['Decodable', 'Identifiable']}>
        <var name="tweets" type="[Tweet_tweets]" />
        <var name="id" type="String" />
        <var name="status" type="TweetStatus" />

        <struct name="Tweet_tweets" inherit={['Decodable']}>
          <var name="postedTweetID" type="String?" />
        </struct>
      </struct>
    </extension>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('fragment with an import', () => {
  const code = (
    <Fragment>
      <import module="Relay" />
      <struct name="Data">
        <var name="foo" type="String" />
        <var name="bar" type="Int?" />
      </struct>
    </Fragment>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('function tagged with availability', () => {
  const code = (
    <extension name="TweetRow_tweetGroup_Key">
      <available
        versions={['iOS 14.0', 'macOS 10.16', 'tvOS 14.0', 'watchOS 7.0']}
      >
        <function
          name="asFragment"
          returns="RelaySwiftUI.FragmentNext<TweetRow_tweetGroup>"
        >
          {'RelaySwiftUI.FragmentNext<TweetRow_tweetGroup>(self)'}
        </function>
      </available>
    </extension>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('public access', () => {
  const code = (
    <Fragment>
      <extension
        name="TweetRow_tweetGroup_Key"
        inherit={['Relay.Operation']}
        access="public"
      >
        <function
          name="asFragment"
          returns="RelaySwiftUI.FragmentNext<TweetRow_tweetGroup>"
          access="public"
        >
          {'RelaySwiftUI.FragmentNext<TweetRow_tweetGroup>(self)'}
        </function>
      </extension>
      <struct name="Data" access="public">
        <var name="foo" type="String" access="public" />
        <var name="bar" type="Int?" access="public" />
      </struct>
    </Fragment>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('property with a function call expression', () => {
  const code = (
    <extension name="TweetList_tweets" inherit={['Relay.PaginationFragment']}>
      <var name="metadata" type="Metadata" isStatic>
        <call
          name="RefetchMetadata"
          parameters={[
            <param label="path">["viewer"]</param>,
            <param label="operation">Operation.self</param>,
            <param label="connection">
              <call
                name="ConnectionMetadata"
                parameters={[
                  <param label="path">["allTweets"]</param>,
                  <param label="forward">
                    <call
                      name="ConnectionVariableConfig"
                      parameters={[
                        <param label="count">"count"</param>,
                        <param label="cursor">"cursor"</param>,
                      ]}
                    />
                  </param>,
                ]}
                expanded
              />
            </param>,
          ]}
          expanded
        />
      </var>
    </extension>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

test('nested components', () => {
  const ConnectionVariableConfig = ({ count, cursor }) => {
    return (
      <call
        name="ConnectionVariableConfig"
        parameters={[
          <param label="count">"{count}"</param>,
          <param label="cursor">"{cursor}"</param>,
        ]}
      />
    );
  };

  const ConnectionMetadata = ({
    path,
    isForward = false,
    isBackward = false,
  }) => {
    return (
      <call
        name="ConnectionMetadata"
        parameters={[
          <param label="path">[{path.map(s => `"${s}"`).join(', ')}]</param>,
          isForward ? (
            <param label="forward">
              <ConnectionVariableConfig count="count" cursor="cursor" />
            </param>
          ) : null,
          isBackward ? (
            <param label="backward">
              <ConnectionVariableConfig count="count" cursor="cursor" />
            </param>
          ) : null,
        ]}
        expanded
      />
    );
  };

  const RefetchMetadata = ({ path, connectionPath }) => {
    return (
      <call
        name="RefetchMetadata"
        parameters={[
          <param label="path">[{path.map(s => `"${s}"`).join(', ')}]</param>,
          <param label="operation">Operation.self</param>,
          <param label="connection">
            <ConnectionMetadata path={connectionPath} isForward />
          </param>,
        ]}
        expanded
      />
    );
  };

  const code = (
    <extension name="TweetList_tweets" inherit={['Relay.PaginationFragment']}>
      <var name="metadata" type="Metadata" isStatic>
        <RefetchMetadata path={['viewer']} connectionPath={['allTweets']} />
      </var>
    </extension>
  );

  expect(renderSwift(code)).toMatchSnapshot();
});

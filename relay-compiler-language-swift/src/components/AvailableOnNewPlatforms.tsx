/** @jsx swiftJSX */

import { swiftJSX, SwiftNode } from '../swiftJSX';

export const AvailableOnNewPlatforms = ({
  children,
}: {
  children?: SwiftNode;
}) => {
  return (
    <available
      versions={['iOS 14.0', 'macOS 10.16', 'tvOS 14.0', 'watchOS 7.0']}
    >
      {children}
    </available>
  );
};

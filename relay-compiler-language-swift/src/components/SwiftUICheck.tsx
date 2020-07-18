/** @jsx swiftJSX */

import { swiftJSX, SwiftNode } from '../swiftJSX';

export const SwiftUICheck = ({ children }: { children?: SwiftNode }) => {
  return (
    <compilecheck condition="swift(>=5.3) && canImport(RelaySwiftUI)">
      {children}
    </compilecheck>
  );
};

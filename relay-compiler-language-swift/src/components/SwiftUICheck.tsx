/** @jsx swiftJSX */

import { swiftJSX, SwiftNode } from '../swiftJSX';

export const SwiftUICheck = ({ children }: { children?: SwiftNode }) => {
  return (
    <compilecheck condition="canImport(RelaySwiftUI)">{children}</compilecheck>
  );
};

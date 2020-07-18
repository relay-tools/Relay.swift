/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';

export const ValueLiteral = ({ value }: { value: any }) => {
  if (value === null) {
    return 'nil';
  }
  if (typeof value === 'boolean') {
    return <literal bool={value} />;
  }
  if (typeof value === 'number') {
    return <literal int={value} />;
  }
  if (typeof value === 'string') {
    return <literal string={value} />;
  }
  return JSON.stringify(value);
};

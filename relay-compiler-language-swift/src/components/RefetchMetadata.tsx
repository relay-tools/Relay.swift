/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ReaderRefetchMetadata } from 'relay-runtime';
import { ConnectionMetadata } from './ConnectionMetadata';

export const RefetchMetadata = ({
  metadata,
}: {
  metadata: ReaderRefetchMetadata;
}) => {
  return (
    <call
      name="RefetchMetadata"
      parameters={[
        <param label="path">
          <literal
            array={metadata.fragmentPathInResult.map(s => (
              <literal string={s} />
            ))}
          />
        </param>,
        (metadata as any).identifierField ? (
          <param label="identifierField">
            <literal string={(metadata as any).identifierField} />
          </param>
        ) : null,
        <param label="operation">Operation.self</param>,
        metadata.connection ? (
          <param label="connection">
            <ConnectionMetadata metadata={metadata.connection} />
          </param>
        ) : null,
      ]}
      expanded
    />
  );
};

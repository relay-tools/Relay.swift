/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import { ReaderPaginationMetadata } from 'relay-runtime';
import { ConnectionVariableConfig } from './ConnectionVariableConfig';

export const ConnectionMetadata = ({
  metadata,
}: {
  metadata: ReaderPaginationMetadata;
}) => {
  return (
    <call
      name="ConnectionMetadata"
      parameters={[
        <param label="path">
          <literal
            array={metadata.path.map(s => (
              <literal string={s} />
            ))}
          />
        </param>,
        metadata.forward ? (
          <param label="forward">
            <ConnectionVariableConfig
              count={metadata.forward.count}
              cursor={metadata.forward.cursor}
            />
          </param>
        ) : null,
        metadata.backward ? (
          <param label="backward">
            <ConnectionVariableConfig
              count={metadata.backward.count}
              cursor={metadata.backward.cursor}
            />
          </param>
        ) : null,
      ]}
      expanded
    />
  );
};

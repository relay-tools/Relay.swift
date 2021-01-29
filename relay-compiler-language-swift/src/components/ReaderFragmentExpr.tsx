/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import {
  ReaderFragment,
  ReaderSelection,
  ReaderScalarField,
  ReaderLinkedField,
} from 'relay-runtime';
import { ArgumentsExpr } from './ArgumentsExpr';
import {
  ReaderClientExtension,
  ReaderFragmentSpread,
  ReaderInlineFragment,
} from 'relay-runtime/lib/util/ReaderNode';

export const ReaderFragmentExpr = ({ node }: { node: ReaderFragment }) => {
  return (
    <call
      name="ReaderFragment"
      parameters={[
        <param label="name">
          <literal string={node.name} />
        </param>,
        <param label="type">
          <literal string={node.type} />
        </param>,
        <param label="selections">
          <ReaderSelections selections={node.selections} />
        </param>,
      ]}
      expanded
    />
  );
};

const ReaderSelections = ({
  selections,
}: {
  selections: readonly ReaderSelection[];
}) => {
  return (
    <literal
      array={selections.map(selection => (
        <ReaderSelectionExpr selection={selection} />
      ))}
      expanded
    />
  );
};

const ReaderSelectionExpr = ({ selection }: { selection: ReaderSelection }) => {
  switch (selection.kind) {
    case 'ScalarField':
      return <ReaderScalarFieldExpr field={selection as any} />;
    case 'LinkedField':
      return <ReaderLinkedFieldExpr field={selection as any} />;
    case 'FragmentSpread':
      return <ReaderFragmentSpreadExpr field={selection as any} />;
    case 'InlineFragment':
      return <ReaderInlineFragmentExpr field={selection as any} />;
    case 'ClientExtension':
      return <ReaderClientExtensionExpr field={selection as any} />;
  }

  throw new Error(`Unsupported reader selection kind '${selection.kind}'`);
};

const ReaderScalarFieldExpr = ({ field }: { field: ReaderScalarField }) => {
  return (
    <call
      receiver=""
      name="field"
      parameters={[
        <param>
          <call
            name="ReaderScalarField"
            parameters={[
              <param label="name">
                <literal string={field.name} />
              </param>,
              field.alias && (
                <param label="alias">
                  <literal string={field.alias} />
                </param>
              ),
              field.storageKey && (
                <param label="storageKey">
                  <literal string={field.storageKey} />
                </param>
              ),
              field.args && (
                <param label="args">
                  <ArgumentsExpr args={field.args} />
                </param>
              ),
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

const ReaderLinkedFieldExpr = ({ field }: { field: ReaderLinkedField }) => {
  return (
    <call
      receiver=""
      name="field"
      parameters={[
        <param>
          <call
            name="ReaderLinkedField"
            parameters={[
              <param label="name">
                <literal string={field.name} />
              </param>,
              field.alias && (
                <param label="alias">
                  <literal string={field.alias} />
                </param>
              ),
              field.storageKey && (
                <param label="storageKey">
                  <literal string={field.storageKey} />
                </param>
              ),
              field.args && (
                <param label="args">
                  <ArgumentsExpr args={field.args} />
                </param>
              ),
              field.concreteType && (
                <param label="concreteType">
                  <literal string={field.concreteType} />
                </param>
              ),
              <param label="plural">
                <literal bool={field.plural} />
              </param>,
              <param label="selections">
                <ReaderSelections selections={field.selections} />
              </param>,
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

const ReaderFragmentSpreadExpr = ({
  field,
}: {
  field: ReaderFragmentSpread;
}) => {
  return (
    <call
      receiver=""
      name="fragmentSpread"
      parameters={[
        <param>
          <call
            name="ReaderFragmentSpread"
            parameters={[
              <param label="name">
                <literal string={field.name} />
              </param>,
              field.args && (
                <param label="args">
                  <ArgumentsExpr args={field.args} />
                </param>
              ),
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

const ReaderInlineFragmentExpr = ({
  field,
}: {
  field: ReaderInlineFragment;
}) => {
  return (
    <call
      receiver=""
      name="inlineFragment"
      parameters={[
        <param>
          <call
            name="ReaderInlineFragment"
            parameters={[
              <param label="type">
                <literal string={field.type} />
              </param>,
              <param label="selections">
                <ReaderSelections selections={field.selections} />
              </param>,
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

const ReaderClientExtensionExpr = ({
  field,
}: {
  field: ReaderClientExtension;
}) => {
  return (
    <call
      receiver=""
      name="clientExtension"
      parameters={[
        <param>
          <call
            name="ReaderClientExtension"
            parameters={[
              <param label="selections">
                <ReaderSelections selections={field.selections} />
              </param>,
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

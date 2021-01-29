/** @jsx swiftJSX */

import { swiftJSX } from '../swiftJSX';
import {
  NormalizationOperation,
  NormalizationSelection,
  NormalizationScalarField,
  NormalizationLinkedField,
} from 'relay-runtime';
import { ArgumentsExpr } from './ArgumentsExpr';
import {
  NormalizationInlineFragment,
  NormalizationHandle,
  NormalizationClientExtension,
} from 'relay-runtime/lib/util/NormalizationNode';

export const NormalizationOperationExpr = ({
  node,
}: {
  node: NormalizationOperation;
}) => {
  return (
    <call
      name="NormalizationOperation"
      parameters={[
        <param label="name">
          <literal string={node.name} />
        </param>,
        <param label="selections">
          <NormalizationSelections selections={node.selections} />
        </param>,
      ]}
      expanded
    />
  );
};

const NormalizationSelections = ({
  selections,
}: {
  selections: readonly NormalizationSelection[];
}) => {
  return (
    <literal
      array={selections.map(selection => (
        <NormalizationSelectionExpr selection={selection} />
      ))}
      expanded
    />
  );
};

const NormalizationSelectionExpr = ({
  selection,
}: {
  selection: NormalizationSelection;
}) => {
  switch (selection.kind) {
    case 'ScalarField':
      return <NormalizationScalarFieldExpr field={selection as any} />;
    case 'LinkedField':
      return <NormalizationLinkedFieldExpr field={selection as any} />;
    case 'ScalarHandle':
    case 'LinkedHandle':
      return <NormalizationHandleExpr field={selection as any} />;
    case 'InlineFragment':
      return <NormalizationInlineFragmentExpr field={selection as any} />;
    case 'ClientExtension':
      return <NormalizationClientExtensionExpr field={selection as any} />;
  }

  throw new Error(
    `Unsupported normalization selection kind '${selection.kind}'`
  );
};

const NormalizationScalarFieldExpr = ({
  field,
}: {
  field: NormalizationScalarField;
}) => {
  return (
    <call
      receiver=""
      name="field"
      parameters={[
        <param>
          <call
            name="NormalizationScalarField"
            parameters={[
              <param label="name">
                <literal string={field.name} />
              </param>,
              field.alias && (
                <param label="alias">
                  <literal string={field.alias} />
                </param>
              ),
              field.args && (
                <param label="args">
                  <ArgumentsExpr args={field.args} />
                </param>
              ),
              field.storageKey && (
                <param label="storageKey">
                  <literal string={field.storageKey} />
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

const NormalizationLinkedFieldExpr = ({
  field,
}: {
  field: NormalizationLinkedField;
}) => {
  return (
    <call
      receiver=""
      name="field"
      parameters={[
        <param>
          <call
            name="NormalizationLinkedField"
            parameters={[
              <param label="name">
                <literal string={field.name} />
              </param>,
              field.alias && (
                <param label="alias">
                  <literal string={field.alias} />
                </param>
              ),
              field.args && (
                <param label="args">
                  <ArgumentsExpr args={field.args} />
                </param>
              ),
              field.storageKey && (
                <param label="storageKey">
                  <literal string={field.storageKey} />
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
                <NormalizationSelections selections={field.selections} />
              </param>,
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

const NormalizationHandleExpr = ({ field }: { field: NormalizationHandle }) => {
  return (
    <call
      receiver=""
      name="handle"
      parameters={[
        <param>
          <call
            name="NormalizationHandle"
            parameters={[
              <param label="kind">
                .{field.kind === 'LinkedHandle' ? 'linked' : 'scalar'}
              </param>,
              <param label="name">
                <literal string={field.name} />
              </param>,
              field.alias && (
                <param label="alias">
                  <literal string={field.alias} />
                </param>
              ),
              field.args && (
                <param label="args">
                  <ArgumentsExpr args={field.args} />
                </param>
              ),
              <param label="handle">
                <literal string={field.handle} />
              </param>,
              <param label="key">
                <literal string={field.key} />
              </param>,
              field.filters && (
                <param label="filters">
                  <literal
                    array={field.filters.map(filter => (
                      <literal string={filter} />
                    ))}
                  />
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

const NormalizationInlineFragmentExpr = ({
  field,
}: {
  field: NormalizationInlineFragment;
}) => {
  return (
    <call
      receiver=""
      name="inlineFragment"
      parameters={[
        <param>
          <call
            name="NormalizationInlineFragment"
            parameters={[
              <param label="type">
                <literal string={field.type} />
              </param>,
              <param label="selections">
                <NormalizationSelections selections={field.selections} />
              </param>,
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

const NormalizationClientExtensionExpr = ({
  field,
}: {
  field: NormalizationClientExtension;
}) => {
  return (
    <call
      receiver=""
      name="clientExtension"
      parameters={[
        <param>
          <call
            name="NormalizationClientExtension"
            parameters={[
              <param label="selections">
                <NormalizationSelections selections={field.selections} />
              </param>,
            ]}
            expanded
          />
        </param>,
      ]}
    />
  );
};

import { FormatModule, Schema } from 'relay-compiler';
import { RunState } from './RunState';
import {
  ConcreteRequest,
  ReaderFragment,
  NormalizationOperation,
  RequestParameters,
  ReaderSelection,
  ReaderArgument,
  NormalizationArgument,
  NormalizationSelection,
} from 'relay-runtime';
import { indent } from './util';

export function formatGeneratedModule(_runState: RunState): FormatModule {
  return ({ schema, node, typeText }: any) => {
    return `// Auto-generated by relay-compiler. Do not edit.

import Relay

${generateNodeStruct(schema, node)}

${typeText}
${generatePostamble(node)}
`;
  };
}

function generateNodeStruct(
  _schema: Schema,
  node: ConcreteRequest | ReaderFragment
): string {
  switch (node.kind) {
    case 'Request':
      return generateConcreteRequestStruct(node as ConcreteRequest);
    case 'Fragment':
      return generateReaderFragmentStruct(node as ReaderFragment);
    default:
      return '';
  }
}

function generatePostamble(node: ConcreteRequest | ReaderFragment): string {
  switch (node.kind) {
    case 'Request':
      return `extension ${
        (node as ConcreteRequest).operation.name
      }: Relay.Operation {}`;
    case 'Fragment':
      const fragment = node as ReaderFragment;
      const fragmentExt = `extension ${fragment.name}: Relay.Fragment {}`;
      if (
        fragment.metadata &&
        fragment.metadata.connection &&
        fragment.metadata.refetch
      ) {
        return `${fragmentExt}

${generatePaginationFragmentExtension(fragment)}`;
      }
      return fragmentExt;
    default:
      return '';
  }
}

function generatePaginationFragmentExtension(node: ReaderFragment): string {
  const refetch = node.metadata.refetch;
  const operationName = (refetch.operation as string)
    .replace('@@MODULE_START@@', '')
    .replace('.graphql@@MODULE_END@@', '');

  let connectionArgs: [string, string][] = [
    [
      'path',
      `[${refetch.connection.path
        .map(elem => (typeof elem === 'string' ? `"${elem}"` : String(elem)))
        .join(', ')}]`,
    ],
  ];

  if (refetch.connection.forward) {
    connectionArgs.push([
      'forward',
      generateConnectionConfigExpr(refetch.connection.forward),
    ]);
  }

  if (refetch.connection.backward) {
    connectionArgs.push([
      'backward',
      generateConnectionConfigExpr(refetch.connection.backward),
    ]);
  }

  return `extension ${node.name}: Relay.PaginationFragment {
${indent(1)}typealias Operation = ${operationName}

${indent(1)}static var metadata: Metadata {
${indent(2)}RefetchMetadata(
${indent(3)}path: [${refetch.fragmentPathInResult
    .map(elem => (typeof elem === 'string' ? `"${elem}"` : String(elem)))
    .join(', ')}],
${indent(3)}operation: Operation.self,
${indent(3)}connection: ConnectionMetadata(
${connectionArgs
  .map(([name, expr]) => `${indent(4)}${name}: ${expr}`)
  .join(',\n')}))
${indent(1)}}
}`;
}

function generateConnectionConfigExpr({
  count,
  cursor,
}: {
  count: string;
  cursor: string;
}): string {
  return `ConnectionVariableConfig(count: "${count}", cursor: "${cursor}")`;
}

function generateConcreteRequestStruct(node: ConcreteRequest): string {
  return `struct ${node.operation.name} {
${indent(1)}var variables: Variables

${indent(1)}init(variables: Variables) {
${indent(2)}self.variables = variables
${indent(1)}}

${indent(1)}static var node: ConcreteRequest {
${indent(2)}ConcreteRequest(
${indent(3)}fragment: ${generateReaderFragmentExpr(node.fragment, 4)},
${indent(3)}operation: ${generateNormalizationOperationExpr(node.operation, 4)},
${indent(3)}params: ${generateRequestParametersExpr(node.params, 4)})
${indent(1)}}
}
`;
}

function generateReaderFragmentStruct(node: ReaderFragment): string {
  return `struct ${node.name} {
${indent(1)}var fragmentPointer: FragmentPointer

${indent(1)}init(key: ${node.name}_Key) {
${indent(2)}fragmentPointer = key.fragment_${node.name}
${indent(1)}}

${indent(1)}static var node: ReaderFragment {
${indent(2)}${generateReaderFragmentExpr(node, 3)}
${indent(1)}}
}
`;
}

function generateReaderFragmentExpr(
  fragment: ReaderFragment,
  level: number
): string {
  return `ReaderFragment(
${indent(level)}name: "${fragment.name}",
${indent(level)}selections: ${generateReaderSelectionsExpr(
    fragment.selections,
    level
  )})`;
}

function generateReaderSelectionsExpr(
  selections: readonly ReaderSelection[],
  level: number
): string {
  return `[
${selections
  .map(selection => generateReaderSelectionExpr(selection, level + 1))
  .join(',\n')}
${indent(level)}]`;
}

function generateReaderSelectionExpr(
  selection: ReaderSelection,
  level: number
): string {
  let typeText = `${indent(level)}`;

  switch (selection.kind) {
    case 'ScalarField':
      typeText += `.field(ReaderScalarField(\n`;
      break;
    case 'LinkedField':
      typeText += `.field(ReaderLinkedField(\n`;
      break;
    case 'FragmentSpread':
      typeText += `.fragmentSpread(ReaderFragmentSpread(\n`;
      break;
  }

  const args: [string, string][] = [];

  if ('name' in selection) {
    args.push(['name', `"${selection.name}"`]);
  }

  if ('alias' in selection && selection.alias) {
    args.push(['alias', `"${selection.alias}"`]);
  }

  if ('args' in selection && selection.args) {
    args.push(['args', generateArgumentsExpr(selection.args, level + 1)]);
  }

  if ('concreteType' in selection && selection.concreteType) {
    args.push(['concreteType', `"${selection.concreteType}"`]);
  }

  if ('plural' in selection) {
    args.push(['plural', selection.plural ? 'true' : 'false']);
  }

  if ('selections' in selection) {
    args.push([
      'selections',
      generateReaderSelectionsExpr(selection.selections, level + 1),
    ]);
  }

  typeText += args
    .map(([name, expr]) => `${indent(level + 1)}${name}: ${expr}`)
    .join(',\n');

  typeText += `\n${indent(level)}))`;

  return typeText;
}

function generateNormalizationOperationExpr(
  operation: NormalizationOperation,
  level: number
): string {
  return `NormalizationOperation(
${indent(level)}name: "${operation.name}",
${indent(level)}selections: ${generateNormalizationSelectionsExpr(
    operation.selections,
    level
  )})`;
}

function generateNormalizationSelectionsExpr(
  selections: readonly NormalizationSelection[],
  level: number
): string {
  return `[
${selections
  .map(selection => generateNormalizationSelectionExpr(selection, level + 1))
  .join(',\n')}
${indent(level)}]`;
}

function generateNormalizationSelectionExpr(
  selection: NormalizationSelection,
  level: number
): string {
  let typeText = `${indent(level)}`;

  switch (selection.kind) {
    case 'ScalarField':
      typeText += `.field(NormalizationScalarField(\n`;
      break;
    case 'LinkedField':
      typeText += `.field(NormalizationLinkedField(\n`;
      break;
    case 'LinkedHandle':
    case 'ScalarHandle':
      typeText += `.handle(NormalizationHandle(
${indent(level + 1)}kind: .${
        selection.kind === 'LinkedHandle' ? 'linked' : 'scalar'
      },
`;
      break;
  }

  const args: [string, string][] = [];

  if ('name' in selection) {
    args.push(['name', `"${selection.name}"`]);
  }

  if ('alias' in selection && selection.alias) {
    args.push(['alias', `"${selection.alias}"`]);
  }

  if ('args' in selection && selection.args) {
    args.push(['args', generateArgumentsExpr(selection.args, level + 1)]);
  }

  if ('handle' in selection && selection.handle) {
    args.push(['handle', `"${selection.handle}"`]);
  }

  if ('key' in selection && selection.key) {
    args.push(['key', `"${selection.key}"`]);
  }

  if ('filters' in selection) {
    args.push([
      'filters',
      `[${selection.filters.map(filter => `"${filter}"`).join(', ')}]`,
    ]);
  }

  if ('storageKey' in selection && selection.storageKey) {
    args.push(['storageKey', `"${selection.storageKey}"`]);
  }

  if ('concreteType' in selection && selection.concreteType) {
    args.push(['concreteType', `"${selection.concreteType}"`]);
  }

  if ('plural' in selection) {
    args.push(['plural', selection.plural ? 'true' : 'false']);
  }

  if ('selections' in selection) {
    args.push([
      'selections',
      generateNormalizationSelectionsExpr(selection.selections, level + 1),
    ]);
  }

  typeText += args
    .map(([name, expr]) => `${indent(level + 1)}${name}: ${expr}`)
    .join(',\n');

  typeText += `\n${indent(level)}))`;

  return typeText;
}

function generateRequestParametersExpr(
  params: RequestParameters,
  level: number
): string {
  return `RequestParameters(
${indent(level)}name: "${params.name}",
${indent(level)}operationKind: .${params.operationKind.toLowerCase()},
${indent(level)}text: """
${params.text}""")`;
}

function generateArgumentsExpr(
  args: readonly ReaderArgument[] | readonly NormalizationArgument[],
  level: number
): string {
  return `[
${(args as any)
  .map(arg => {
    switch (arg.kind) {
      case 'Literal':
        return `${indent(level + 1)}LiteralArgument(name: "${
          arg.name
        }", value: ${argumentLiteral(arg.value)})`;
      case 'Variable':
        return `${indent(level + 1)}VariableArgument(name: "${
          arg.name
        }", variableName: "${arg.variableName}")`;
      default:
        return '';
    }
  })
  .join(',\n')}
${indent(level)}]`;
}

function argumentLiteral(value: any): string {
  if (value === null) {
    return 'nil';
  } else if (typeof value === 'boolean') {
    return value ? 'true' : 'false';
  } else {
    return JSON.stringify(value);
  }
}

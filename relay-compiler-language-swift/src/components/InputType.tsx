/** @jsx swiftJSX */

import { swiftJSX, DeclarationGroup } from '../swiftJSX';
import { InputStructNode } from '../SwiftGeneratorDataTypes';
import { SwiftUICheck } from './SwiftUICheck';
import { AvailableOnNewPlatforms } from './AvailableOnNewPlatforms';

export const InputType = ({ node }: { node: InputStructNode }) => {
  if (node.name.indexOf('.') !== -1) {
    const [parentType, childType] = node.name.split('.');

    return (
      <DeclarationGroup>
        <extension name={parentType}>
          <InputType node={{ ...node, name: childType }} />
        </extension>
        <QueryGetConvenienceExtension node={node} />
      </DeclarationGroup>
    );
  }

  return node.fields.length ? (
    <DeclarationGroup>
      <struct name={node.name} inherit={['VariableDataConvertible']}>
        <DeclarationGroup>
          {node.fields.map(field =>
            field.fieldName == null ? null : (
              <var name={field.fieldName} type={field.typeName} />
            )
          )}
          <var name="variableData" type="VariableData">
            <literal
              dict={node.fields.map(field =>
                field.fieldName == null
                  ? null
                  : [<literal string={field.fieldName} />, field.fieldName]
              )}
              expanded
            />
          </var>
        </DeclarationGroup>
      </struct>
      <QueryVariablesConvenienceInitializer node={node} />
    </DeclarationGroup>
  ) : (
    <typealias name={node.name}>EmptyVariables</typealias>
  );
};

const QueryGetConvenienceExtension = ({ node }: { node: InputStructNode }) => {
  if (!node.isRootVariables || node.fields.length === 0) {
    return null;
  }

  const [parentType] = node.name.split('.');

  return (
    <SwiftUICheck>
      <DeclarationGroup>
        <import module="RelaySwiftUI" />
        <AvailableOnNewPlatforms>
          <extension
            name="RelaySwiftUI.QueryNext.WrappedValue"
            where={[`O == ${parentType}`]}
          >
            <function
              name="get"
              parameters={[
                ...node.fields.map(field => (
                  <paramdecl
                    name={field.fieldName}
                    type={field.typeName}
                    defaultValue={
                      field.typeName.endsWith('?') ? 'nil' : undefined
                    }
                  />
                )),
                <paramdecl name="fetchKey" type="Any?" defaultValue="nil" />,
              ]}
              returns={`RelaySwiftUI.QueryNext<${parentType}>.Result`}
            >
              <call
                receiver="self"
                name="get"
                parameters={[
                  <param>
                    <call
                      receiver=""
                      name="init"
                      parameters={node.fields.map(field => (
                        <param label={field.fieldName}>{field.fieldName}</param>
                      ))}
                    />
                  </param>,
                  <param label="fetchKey">fetchKey</param>,
                ]}
              />
            </function>
          </extension>
        </AvailableOnNewPlatforms>
      </DeclarationGroup>
    </SwiftUICheck>
  );
};

const QueryVariablesConvenienceInitializer = ({
  node,
}: {
  node: InputStructNode;
}) => {
  if (!node.isRootVariables) {
    return null;
  }

  return (
    <init
      parameters={node.fields.map(field => (
        <paramdecl
          name={field.fieldName}
          type={field.typeName}
          defaultValue={field.typeName.endsWith('?') ? 'nil' : undefined}
        />
      ))}
    >
      <call
        receiver="self"
        name="init"
        parameters={[
          <param label="variables">
            <call
              receiver=""
              name="init"
              parameters={node.fields.map(field => (
                <param label={field.fieldName}>{field.fieldName}</param>
              ))}
            />
          </param>,
        ]}
      />
    </init>
  );
};

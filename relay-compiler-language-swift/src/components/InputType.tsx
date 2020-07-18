/** @jsx swiftJSX */

import { swiftJSX, Fragment } from '../swiftJSX';
import { InputStructNode } from '../SwiftGeneratorDataTypes';
import { SwiftUICheck } from './SwiftUICheck';
import { AvailableOnNewPlatforms } from './AvailableOnNewPlatforms';

export const InputType = ({ node }: { node: InputStructNode }) => {
  if (node.name.indexOf('.') !== -1) {
    const [parentType, childType] = node.name.split('.');

    return (
      <Fragment>
        <extension name={parentType}>
          <InputType node={{ ...node, name: childType }} />
        </extension>
        <QueryGetConvenienceExtension node={node} />
      </Fragment>
    );
  }

  return node.fields.length ? (
    <Fragment>
      <struct name={node.name} inherit={['VariableDataConvertible']}>
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
      </struct>
      <QueryVariablesConvenienceInitializer node={node} />
    </Fragment>
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

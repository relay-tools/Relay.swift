import { Schema, TypeID } from 'relay-compiler';
import { State } from './State';
import { TypeGeneratorOptions } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { InputStructNode, FieldNode } from 'SwiftGeneratorDataTypes';

export function transformScalarType(
  schema: Schema,
  type: TypeID,
  state: State
) {
  if (schema.isNonNull(type)) {
    return transformNonNullableScalarType(
      schema,
      schema.getNullableType(type),
      state
    );
  } else {
    return `${transformNonNullableScalarType(schema, type, state)}?`;
  }
}

function transformNonNullableScalarType(
  schema: Schema,
  type: TypeID,
  state: State
) {
  if (schema.isList(type)) {
    return `[${transformScalarType(
      schema,
      schema.getListItemType(type),
      state
    )}]`;
  } else if (
    schema.isObject(type) ||
    schema.isUnion(type) ||
    schema.isInterface(type)
  ) {
    return ''; // TODO
  } else if (schema.isScalar(type)) {
    return transformGraphQLScalarType(schema.getTypeString(type), state);
  } else if (schema.isEnum(type)) {
    return transformGraphQLEnumType(schema, schema.assertEnumType(type), state);
  } else {
    throw new Error(`Could not convert from GraphQL type ${String(type)}`);
  }
}

function transformGraphQLScalarType(
  typeName: string,
  options: TypeGeneratorOptions
) {
  const customType = options.customScalars[typeName];

  switch (customType ?? typeName) {
    case 'ID':
    case 'String':
      return `String`;
    case 'Int':
      return `Int`;
    case 'Float':
      return `Double`;
    case 'Boolean':
      return `Bool`;
    default:
      return customType == null ? `Any` : customType;
  }
}

function transformGraphQLEnumType(schema: Schema, type: TypeID, state: State) {
  state.usedEnums[schema.getTypeString(type)] = type;
  return schema.getTypeString(schema.getTypeString(type));
}

interface TransformedObjectType {
  kind: 'Object' | 'Union' | 'Interface';
  typeString: string;
  baseTypeString: string;
  originalTypeName: string;
}

export function transformObjectType(
  schema: Schema,
  type: TypeID,
  alias: string,
  state: State
): TransformedObjectType {
  if (schema.isNonNull(type)) {
    return transformNonNullableObjectType(
      schema,
      schema.getNullableType(type),
      alias,
      state
    );
  } else {
    const { typeString, ...rest } = transformNonNullableObjectType(
      schema,
      type,
      alias,
      state
    );
    return { typeString: `${typeString}?`, ...rest };
  }
}

function transformNonNullableObjectType(
  schema: Schema,
  type: TypeID,
  alias: string,
  state: State
): TransformedObjectType {
  if (schema.isList(type)) {
    const { typeString, ...rest } = transformObjectType(
      schema,
      schema.getListItemType(type),
      alias,
      state
    );
    return { typeString: `[${typeString}]`, ...rest };
  } else if (
    schema.isObject(type) ||
    schema.isUnion(type) ||
    schema.isInterface(type)
  ) {
    let kind: TransformedObjectType['kind'];
    if (schema.isObject(type)) {
      kind = 'Object';
    } else if (schema.isUnion(type)) {
      kind = 'Union';
    } else if (schema.isInterface(type)) {
      kind = 'Interface';
    } else {
      throw new Error('Unexpected type');
    }
    let typeString = schema.getTypeString(type);
    if (alias) {
      typeString = `${typeString}_${alias}`;
    }
    return {
      typeString,
      baseTypeString: typeString,
      originalTypeName: schema.getTypeString(type),
      kind,
    };
  } else {
    throw new Error(`Could not convert from GraphQL type ${String(type)}`);
  }
}

export function transformInputType(schema: Schema, type: TypeID, state: State) {
  if (schema.isNonNull(type)) {
    return transformNonNullableInputType(
      schema,
      schema.getNullableType(type),
      state
    );
  } else {
    return `${transformNonNullableInputType(schema, type, state)}?`;
  }
}

function transformNonNullableInputType(
  schema: Schema,
  type: TypeID,
  state: State
) {
  if (schema.isList(type)) {
    return `[${transformInputType(
      schema,
      schema.getListItemType(type),
      state
    )}]`;
  } else if (schema.isScalar(type)) {
    return transformGraphQLScalarType(schema.getTypeString(type), state);
  } else if (schema.isEnum(type)) {
    return transformGraphQLEnumType(schema, schema.assertEnumType(type), state);
  } else if (schema.isInputObject(type)) {
    return transformGraphQLInputObjectType(
      schema,
      schema.assertInputObjectType(type),
      state
    );
  } else if (schema.isEnum(type)) {
    return transformGraphQLEnumType(schema, schema.assertEnumType(type), state);
  }
}

function transformGraphQLInputObjectType(
  schema: Schema,
  type: TypeID,
  state: State
) {
  const typeIdentifier = schema.getTypeString(type);
  if (state.generatedInputObjects[typeIdentifier]) {
    return typeIdentifier;
  }

  // we call into this recursively, so this prevents us from visiting the same type twice
  state.generatedInputObjects[typeIdentifier] = 'pending';

  const typeFields = schema.getFields(schema.assertInputObjectType(type));
  const fields: FieldNode[] = typeFields.map(fieldID => {
    const fieldType = schema.getFieldType(fieldID);
    const fieldName = schema.getFieldName(fieldID);
    return {
      kind: 'field',
      fieldName,
      typeName: transformInputType(schema, fieldType, state),
    };
  });

  const struct: InputStructNode = {
    kind: 'inputStruct',
    name: typeIdentifier,
    fields,
  };

  state.generatedInputObjects[typeIdentifier] = struct;
  return typeIdentifier;
}

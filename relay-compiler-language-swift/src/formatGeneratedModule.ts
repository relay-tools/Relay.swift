import * as path from 'path';
import { execFileSync } from 'child_process';
import { FormatModule, Schema } from 'relay-compiler';

const toolPath = path.join(__dirname, 'generate-type-defs');

export const formatGeneratedModule: FormatModule = ({ node, schema }: any) => {
  const theSchema = schema as Schema;

  const schemaTypes = {};
  for (const typeID of theSchema.getTypes()) {
    const fieldsByName = {};

    if (theSchema.isObject(typeID)) {
      for (const field of theSchema.getFields(typeID)) {
        const isPlural = theSchema.isList(
          theSchema.getNullableType(field.type)
        );
        fieldsByName[field.name] = {
          type: field.type.toString(),
          rawType: theSchema.getRawType(field.type),
          isNonNull: theSchema.isNonNull(field.type),
          isPlural: isPlural,
          isNonNullItems:
            isPlural &&
            theSchema.isNonNull(theSchema.getListItemType(field.type)),
        };
      }
    }

    schemaTypes[typeID.name] = {
      fields: fieldsByName,
    };
  }

  const payload = JSON.stringify({ ...node, schemaTypes });

  return execFileSync(toolPath, { input: payload }).toString('utf8');
};

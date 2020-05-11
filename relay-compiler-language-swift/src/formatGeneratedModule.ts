import * as path from 'path';
import { execFileSync } from 'child_process';
import { FormatModule, Schema } from 'relay-compiler';

const toolPath = path.join(__dirname, 'generate-type-defs');

export function formatGeneratedModule(): FormatModule {
  let generatedTypes = new Set<string>();
  let includedTypealiases = false;

  return ({ node, schema, typeText }: any) => {
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
            name: field.name,
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
        name: typeID.name,
        fields: fieldsByName,
        isScalar: theSchema.isScalar(typeID),
        isObject: theSchema.isObject(typeID),
        isEnum: theSchema.isEnum(typeID),
        enumValues: theSchema.isEnum(typeID)
          ? theSchema.getEnumValues(typeID)
          : null,
      };
    }

    const payload = JSON.stringify({
      ...node,
      schemaTypes,
      existingTypes: Array.from(generatedTypes),
    });
    console.log('\n\n\n' + payload);
    let result = execFileSync(toolPath, ['-'], { input: payload }).toString(
      'utf8'
    );

    const lines = result.split('\n');

    for (const line of lines) {
      const match = line.match(/^enum (\w+): /);
      if (!match) {
        continue;
      }

      const name = match[1];
      generatedTypes.add(name);
    }

    if (!includedTypealiases) {
      const { customScalars } = JSON.parse(typeText);

      if (Object.keys(customScalars).length) {
        result += '\n';
        for (const typeName of Object.keys(customScalars)) {
          result += `typealias ${typeName} = ${customScalars[typeName]}\n`;
        }
      }

      includedTypealiases = true;
    }

    return result;
  };
}

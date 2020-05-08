import * as path from 'path';
import { GraphQLTagFinder } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { execFileSync } from 'child_process';

const toolPath = path.join(__dirname, 'find-graphql-tags');

export const find: GraphQLTagFinder = (_text, filePath) => {
  const output = execFileSync(toolPath, [filePath]);
  return JSON.parse(output);
};

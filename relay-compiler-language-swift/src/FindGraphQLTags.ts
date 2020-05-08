import { GraphQLTagFinder } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { execFileSync } from 'child_process';

const toolPath =
  '/Users/matt/Projects/Relay/relay-swift-tools/.build/x86_64-apple-macosx/release/find-graphql-tags';

export const find: GraphQLTagFinder = (_text, filePath) => {
  const output = execFileSync(toolPath, [filePath]);
  return JSON.parse(output);
};

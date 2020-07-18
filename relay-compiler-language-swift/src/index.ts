import { PluginInterface } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { find } from './FindGraphQLTags';
import { SwiftGenerator } from './SwiftGenerator';
import { formatGeneratedModule } from './formatGeneratedModule';
import { RunState } from './RunState';

import * as path from 'path';
import * as fs from 'fs';

export default function plugin(): PluginInterface {
  const runState = new RunState();
  return {
    inputExtensions: ['swift'],
    outputExtension: 'swift',
    getFileFilter(baseDir: string) {
      return (file: any) => {
        runState.reset();
        const filePath = path.join(baseDir, file.relPath);
        let text = '';
        try {
          text = fs.readFileSync(filePath, 'utf8');
        } catch {
          // eslint-disable no-console
          console.warn(
            `RelaySourceModuleParser: Unable to read the file "${filePath}". Looks like it was removed.`
          );
          return false;
        }
        return text.indexOf('graphql') >= 0;
      };
    },
    findGraphQLTags: find,
    formatModule: formatGeneratedModule(),
    typeGenerator: SwiftGenerator(runState),
  } as any;
}

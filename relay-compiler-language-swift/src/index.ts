import { PluginInterface } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { find } from './FindGraphQLTags';
import * as SwiftGenerator from './SwiftGenerator';
import { formatGeneratedModule } from './formatGeneratedModule';

export default function plugin(): PluginInterface {
  return {
    inputExtensions: ['swift'],
    outputExtension: 'swift',
    findGraphQLTags: find,
    formatModule: formatGeneratedModule(),
    typeGenerator: SwiftGenerator,
  };
}

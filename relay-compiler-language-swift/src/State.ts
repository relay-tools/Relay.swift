import { TypeGeneratorOptions } from 'relay-compiler/lib/language/RelayLanguagePluginInterface';
import { InputStructNode } from 'SwiftGeneratorDataTypes';

export interface State extends TypeGeneratorOptions {
  usedEnums: Record<string, string>;
  generatedInputObjects: Record<string, 'pending' | InputStructNode>;
}

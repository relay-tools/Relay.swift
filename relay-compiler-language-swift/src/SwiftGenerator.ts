import { TypeGenerator } from 'relay-compiler';

export const generate: TypeGenerator['generate'] = (
  _schema,
  _node,
  options
) => {
  return JSON.stringify({ customScalars: options.customScalars });
};

export const transforms = [];

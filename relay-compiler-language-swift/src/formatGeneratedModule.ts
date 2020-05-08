import { FormatModule } from 'relay-compiler';

export const formatGeneratedModule: FormatModule = ({
  moduleName,
  node,
  documentType,
  docText,
  concreteText,
  typeText,
  hash,
  sourceHash,
}) => {
  return `
/* moduleName = ${moduleName} */
/* node = ${JSON.stringify(node, null, 4)} */
/* documentType = ${documentType} */
/* docText = ${docText} */
/* concreteText = ${concreteText} */
/* typeText = ${typeText} */
/* hash = ${hash} */
/* sourceHash = ${sourceHash} */
`;
};

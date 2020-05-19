export function indent(level: number): string {
  return '    '.repeat(level);
}

export function stringLiteral(str: string): string {
  return JSON.stringify(str);
}

export interface SwiftElement {
  type: string | SwiftComponent;
  props: any;
}
export type SwiftChild = SwiftElement | string;
export type SwiftNode = null | undefined | SwiftChild | SwiftFragment;
export type SwiftFragment = SwiftNode[];
export type SwiftComponent<Props = any> = (props: Props) => SwiftElement | null;

export function swiftJSX(
  tagName: string | SwiftComponent,
  attrs: any,
  ...children: SwiftNode[]
): SwiftElement | null {
  return { type: tagName, props: { ...attrs, children } };
}

export const Fragment = 'swiftFragment';

export function renderSwift(element: SwiftElement): string {
  const renderer = new Renderer();
  _renderSwift(renderer, element);
  return renderer.text;
}

interface RenderContext {
  inline?: boolean;
  inProtocol?: boolean;
  inSwitch?: boolean;
}

function _renderSwift(
  renderer: Renderer,
  element: SwiftNode,
  context: RenderContext = {}
) {
  if (!element) {
    return;
  }

  if (Array.isArray(element)) {
    for (const node of element) {
      _renderSwift(renderer, node, context);
    }
    return;
  }

  if (typeof element === 'string') {
    if (context.inline) {
      renderer.append(element);
    } else {
      renderer.appendLine(element);
    }
    return;
  }

  if (typeof element.type === 'string') {
    switch (element.type) {
      case 'swiftFragment':
        return _renderSwift(renderer, element.props.children);
      case 'init':
        return renderSwiftInit(renderer, element.props);
      case 'function':
        return renderSwiftFunction(renderer, element.props);
      case 'paramdecl':
        return renderSwiftFunctionParam(renderer, element.props);
      case 'struct':
        return renderSwiftStruct(renderer, element.props);
      case 'var':
        return renderSwiftVar(renderer, element.props, context);
      case 'extension':
        return renderSwiftExtension(renderer, element.props);
      case 'protocol':
        return renderSwiftProtocol(renderer, element.props);
      case 'enum':
        return renderSwiftEnum(renderer, element.props);
      case 'case':
        return renderSwiftCase(renderer, element.props, context);
      case 'import':
        return renderSwiftImport(renderer, element.props);
      case 'available':
        return renderSwiftAvailable(renderer, element.props);
      case 'call':
        return renderSwiftCall(renderer, element.props);
      case 'param':
        return renderSwiftParam(renderer, element.props, context);
      case 'compilecheck':
        return renderSwiftCompileTimeCheck(renderer, element.props);
      case 'typealias':
        return renderSwiftTypealias(renderer, element.props);
      case 'literal':
        return renderSwiftLiteral(renderer, element.props, context);
      case 'switch':
        return renderSwiftSwitch(renderer, element.props);
    }
  } else {
    const rendered = element.type(element.props);
    if (!rendered) {
      return;
    }
    return _renderSwift(renderer, rendered, context);
  }
}

class Renderer {
  private lines: string[];
  private level: number;
  private shouldContinue: boolean;

  constructor() {
    this.lines = [];
    this.level = 0;
    this.shouldContinue = false;
  }

  appendLine(line: string) {
    if (this.shouldContinue) {
      this.append(line);
    } else {
      this.lines.push('    '.repeat(this.level) + line);
    }
  }

  append(text: string) {
    if (this.shouldContinue) {
      this.shouldContinue = false;
    }

    if (this.lines.length) {
      this.lines[this.lines.length - 1] += text;
    } else {
      this.appendLine(text);
    }
  }

  continueLine() {
    this.shouldContinue = true;
  }

  indent() {
    this.level++;
  }

  outdent() {
    this.level--;
  }

  get text(): string {
    return this.lines.join('\n');
  }
}

type AccessLevel = 'public' | 'internal' | 'fileprivate' | 'private';

function renderSwiftStruct(
  renderer: Renderer,
  {
    name,
    inherit = [],
    access,
    children,
  }: {
    name: string;
    inherit?: string[];
    access?: AccessLevel;
    children: SwiftNode[];
  }
) {
  renderer.appendLine(
    `${access ? `${access} ` : ''}struct ${name}${
      inherit.length ? `: ${inherit.join(', ')}` : ''
    } {`
  );
  renderer.indent();

  _renderSwift(renderer, children);

  renderer.outdent();
  renderer.appendLine('}');
}

function renderSwiftVar(
  renderer: Renderer,
  {
    name,
    type,
    isStatic = false,
    access,
    children,
  }: {
    name: string;
    type: string;
    isStatic?: boolean;
    access?: AccessLevel;
    children: SwiftNode[];
  },
  context: RenderContext = {}
) {
  renderer.appendLine(
    `${access ? `${access} ` : ''}${
      isStatic ? 'static ' : ''
    }var ${name}: ${type}`
  );

  if (context.inProtocol) {
    renderer.append(' { get }');
    return;
  }

  if (children.length) {
    renderer.append(' {');
    renderer.indent();

    _renderSwift(renderer, children, context);

    renderer.outdent();
    renderer.appendLine('}');
  }
}

function renderSwiftFunction(
  renderer: Renderer,
  {
    name,
    parameters = [],
    returns,
    isStatic = false,
    access,
    children,
  }: {
    name: string;
    parameters: SwiftNode[];
    returns?: string;
    isStatic?: boolean;
    access?: AccessLevel;
    children: SwiftNode[];
  }
) {
  renderer.appendLine(
    `${access ? `${access} ` : ''}${isStatic ? 'static ' : ''}func ${name}(`
  );
  for (let i = 0; i < parameters.length; i++) {
    if (i !== 0) {
      renderer.append(', ');
    }
    _renderSwift(renderer, parameters[i], { inline: true });
  }
  renderer.append(`)`);

  if (returns) {
    renderer.append(` -> ${returns}`);
  }

  renderer.append(` {`);
  renderer.indent();

  _renderSwift(renderer, children);

  renderer.outdent();
  renderer.appendLine('}');
}

function renderSwiftInit(
  renderer: Renderer,
  {
    parameters = [],
    access,
    throws = false,
    children,
  }: {
    parameters: SwiftNode[];
    access?: AccessLevel;
    throws: boolean;
    children: SwiftNode[];
  }
) {
  renderer.appendLine(`${access ? `${access} ` : ''}init(`);
  for (let i = 0; i < parameters.length; i++) {
    if (i !== 0) {
      renderer.append(', ');
    }
    _renderSwift(renderer, parameters[i], { inline: true });
  }
  renderer.append(')');
  if (throws) {
    renderer.append(' throws');
  }
  renderer.append(' {');
  renderer.indent();

  _renderSwift(renderer, children);

  renderer.outdent();
  renderer.appendLine('}');
}

function renderSwiftFunctionParam(
  renderer: Renderer,
  {
    label,
    name,
    type,
    defaultValue,
  }: {
    label?: string;
    name: string;
    type: string;
    defaultValue?: SwiftNode;
  }
) {
  if (label) {
    renderer.append(`${label} `);
  }
  renderer.append(`${name}: ${type}`);
  if (defaultValue) {
    renderer.append(' = ');
    _renderSwift(renderer, defaultValue, { inline: true });
  }
}

function renderSwiftExtension(
  renderer: Renderer,
  {
    name,
    inherit = [],
    where = [],
    access,
    children,
  }: {
    name: string;
    inherit?: string[];
    where?: string[];
    access?: AccessLevel;
    children: SwiftNode[];
  }
) {
  renderer.appendLine(`${access ? `${access} ` : ''}extension ${name}`);
  if (inherit.length) {
    renderer.append(`: ${inherit.join(', ')}`);
  }
  if (where.length) {
    renderer.append(` where ${where.join(', ')}`);
  }
  renderer.append(' {');

  if (!children.length) {
    renderer.append('}');
    return;
  }

  renderer.indent();
  _renderSwift(renderer, children);
  renderer.outdent();
  renderer.appendLine('}');
}

function renderSwiftProtocol(
  renderer: Renderer,
  {
    name,
    access,
    children,
  }: {
    name: string;
    access?: AccessLevel;
    children: SwiftNode[];
  }
) {
  renderer.appendLine(`${access ? `${access} ` : ''}protocol ${name} {`);
  renderer.indent();

  _renderSwift(renderer, children, { inProtocol: true });

  renderer.outdent();
  renderer.appendLine('}');
}

function renderSwiftEnum(
  renderer: Renderer,
  {
    name,
    inherit = [],
    access,
    children,
  }: {
    name: string;
    inherit: string[];
    access?: AccessLevel;
    children: SwiftNode[];
  }
) {
  renderer.appendLine(`${access ? `${access} ` : ''}enum ${name}`);
  if (inherit.length) {
    renderer.append(`: ${inherit.join(', ')}`);
  }
  renderer.append(' {');
  renderer.indent();

  _renderSwift(renderer, children);

  renderer.outdent();
  renderer.appendLine('}');
}

function renderSwiftCase(
  renderer: Renderer,
  {
    name,
    parameters = [],
    isDefault = false,
    children,
  }: {
    name?: SwiftNode;
    parameters?: SwiftNode[];
    isDefault: boolean;
    children: SwiftNode[];
  },
  context: RenderContext = {}
) {
  if (isDefault) {
    renderer.appendLine('default');
  } else {
    renderer.appendLine('case ');
    _renderSwift(renderer, name, { inline: true });

    if (parameters.length) {
      renderer.append('(');

      for (let i = 0; i < parameters.length; i++) {
        if (i !== 0) {
          renderer.append(', ');
        }
        _renderSwift(renderer, parameters[i], { inline: true });
      }

      renderer.append(')');
    }
  }

  if (context.inSwitch) {
    renderer.append(':');
    renderer.indent();

    _renderSwift(renderer, children, context);

    renderer.outdent();
  } else {
    if (children.length) {
      renderer.append(' = ');
      _renderSwift(renderer, children, { inline: true });
    }
  }
}

function renderSwiftImport(
  renderer: Renderer,
  {
    module,
  }: {
    module: string;
  }
) {
  renderer.appendLine(`import ${module}`);
}

function renderSwiftAvailable(
  renderer: Renderer,
  {
    versions,
    children,
  }: {
    versions: string[];
    children: SwiftNode[];
  }
) {
  renderer.appendLine(`@available(${versions.join(', ')}, *)`);
  _renderSwift(renderer, children);
}

function renderSwiftCall(
  renderer: Renderer,
  {
    receiver,
    name,
    parameters = [],
    expanded = false,
  }: {
    receiver?: SwiftNode;
    name: string;
    parameters?: SwiftNode[];
    expanded?: boolean;
  }
) {
  renderer.appendLine(`${receiver != null ? `${receiver}.` : ''}${name}(`);
  if (expanded) {
    renderer.indent();
  }

  parameters = parameters.filter(p => !!p);
  for (let i = 0; i < parameters.length; i++) {
    if (i !== 0) {
      renderer.append(',');
      if (!expanded) {
        renderer.append(' ');
      }
    }
    _renderSwift(renderer, parameters[i], { inline: !expanded });
  }

  if (expanded) {
    renderer.outdent();
    renderer.appendLine(')');
  } else {
    renderer.append(')');
  }
}

function renderSwiftParam(
  renderer: Renderer,
  {
    label,
    children,
  }: {
    label?: string;
    children: SwiftNode[];
  },
  context: RenderContext = {}
) {
  const text = `${label ? `${label}: ` : ''}`;
  if (context.inline) {
    renderer.append(text);
  } else {
    renderer.appendLine(text);
  }

  renderer.continueLine();
  _renderSwift(renderer, children, { ...context, inline: true });
}

function renderSwiftCompileTimeCheck(
  renderer: Renderer,
  {
    condition,
    children,
  }: {
    condition: SwiftNode;
    children: SwiftNode[];
  }
) {
  renderer.appendLine('#if ');

  _renderSwift(renderer, condition, { inline: true });
  _renderSwift(renderer, children);

  renderer.appendLine('#endif');
}

function renderSwiftTypealias(
  renderer: Renderer,
  {
    name,
    children,
    access,
  }: {
    name: string;
    children: SwiftNode[];
    access?: AccessLevel;
  }
) {
  renderer.appendLine(`${access ? `${access} ` : ''}typealias ${name} = `);
  _renderSwift(renderer, children, { inline: true });
}

type SwiftLiteralProps =
  | { string: string }
  | { int: number }
  | { bool: boolean }
  | { array: SwiftNode[]; expanded?: boolean }
  | { dict: [SwiftNode, SwiftNode][]; expanded?: boolean };

function renderSwiftLiteral(
  renderer: Renderer,
  props: SwiftLiteralProps,
  context: RenderContext
) {
  const appendLine = context.inline
    ? text => {
        renderer.append(text);
      }
    : text => {
        renderer.appendLine(text);
      };

  if ('string' in props) {
    appendLine(JSON.stringify(props.string));
  } else if ('int' in props) {
    appendLine(String(props.int));
  } else if ('bool' in props) {
    appendLine(String(props.bool));
  } else if ('array' in props) {
    appendLine('[');
    renderer.indent();

    const innerContext = { ...context, inline: !props.expanded };

    for (let i = 0; i < props.array.length; i++) {
      if (i !== 0) {
        renderer.append(',');
        if (innerContext.inline) {
          renderer.append(' ');
        }
      }

      _renderSwift(renderer, props.array[i], innerContext);
    }

    renderer.outdent();
    if (props.expanded) {
      renderer.appendLine(']');
    } else {
      renderer.append(']');
    }
  } else if ('dict' in props) {
    appendLine('[');
    renderer.indent();

    const innerContext = { ...context, inline: !props.expanded };

    for (let i = 0; i < props.dict.length; i++) {
      if (i !== 0) {
        renderer.append(',');
        if (innerContext.inline) {
          renderer.append(' ');
        }
      }

      const [key, value] = props.dict[i];
      _renderSwift(renderer, key, innerContext);
      renderer.append(': ');
      renderer.continueLine();
      _renderSwift(renderer, value, innerContext);
    }

    renderer.outdent();
    if (props.expanded) {
      renderer.appendLine(']');
    } else {
      renderer.append(']');
    }
  } else {
    throw new Error('unrecognized props for literal');
  }
}

function renderSwiftSwitch(
  renderer: Renderer,
  {
    value,
    children,
  }: {
    value: SwiftNode;
    children: SwiftNode[];
  }
) {
  renderer.appendLine('switch ');
  _renderSwift(renderer, value, { inline: true });
  renderer.append(' {');

  _renderSwift(renderer, children, { inSwitch: true });

  renderer.appendLine('}');
}

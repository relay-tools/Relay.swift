export interface SwiftElement {
  type: string | SwiftComponent;
  props: any;
}
export type SwiftChild = SwiftElement | string;
export type SwiftNode = null | undefined | SwiftChild | SwiftFragment;
export type SwiftFragment = SwiftNode[];
export type SwiftComponent<Props = any> = (props: Props) => SwiftElement | null;

type CollapsibleNodeKind = 'var' | 'case' | 'import';

export function swiftJSX(
  tagName: string | SwiftComponent,
  attrs: any,
  ...children: SwiftNode[]
): SwiftElement | null {
  return { type: tagName, props: { ...attrs, children } };
}

export const Fragment = 'swiftFragment';
export const DeclarationGroup = 'swiftDeclarationGroup';

export function renderSwift(
  element: SwiftElement,
  options?: {
    defaultAccessLevel?: AccessLevel;
  }
): string {
  const renderer = new Renderer();
  _renderSwift(renderer, element, {
    defaultAccessLevel: options?.defaultAccessLevel,
  });
  return renderer.text;
}

interface RenderContext {
  inline?: boolean;
  inProtocol?: boolean;
  inSwitch?: boolean;
  defaultAccessLevel?: AccessLevel;
}

interface BuiltinRenderFunction<Props> {
  (renderer: Renderer, props: Props, context: RenderContext): void;
}

const builtins: Record<string, BuiltinRenderFunction<any>> = {
  [Fragment]: (renderer, props, context) => {
    _renderSwift(renderer, props.children, context);
  },

  [DeclarationGroup]: (
    renderer,
    { children }: { children: SwiftNode[] },
    context
  ) => {
    let previousNodeKind: CollapsibleNodeKind | null = null;

    children = children.flat().filter(child => child != null);

    for (let i = 0; i < children.length; i++) {
      const child = children[i];

      let newNodeKind: CollapsibleNodeKind | null = null;
      if (typeof child === 'object' && 'type' in child) {
        if (child.type === 'var' && !child.props.children.length) {
          newNodeKind = 'var';
        } else if (child.type === 'case') {
          newNodeKind = 'case';
        } else if (child.type === 'import') {
          newNodeKind = 'import';
        }
      }

      if (i !== 0) {
        if (
          previousNodeKind === null ||
          newNodeKind === null ||
          previousNodeKind !== newNodeKind
        ) {
          renderer.appendLine('');
        }
      }

      _renderSwift(renderer, child, context);
      previousNodeKind = newNodeKind;
    }
  },

  import(renderer, { module }: { module: string }) {
    renderer.appendLine(`import ${module}`);
  },

  struct(
    renderer,
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
    },
    context
  ) {
    renderer.appendLine(formatAccess(access, context));
    renderer.append(
      `struct ${name}${inherit.length ? `: ${inherit.join(', ')}` : ''} {`
    );
    renderer.indent();

    _renderSwift(renderer, children, context);

    renderer.outdent();
    renderer.appendLine('}');
  },

  enum(
    renderer,
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
    },
    context
  ) {
    renderer.appendLine(formatAccess(access, context));
    renderer.append(`enum ${name}`);
    if (inherit.length) {
      renderer.append(`: ${inherit.join(', ')}`);
    }
    renderer.append(' {');
    renderer.indent();

    _renderSwift(renderer, children, context);

    renderer.outdent();
    renderer.appendLine('}');
  },

  protocol(
    renderer,
    {
      name,
      access,
      children,
    }: {
      name: string;
      access?: AccessLevel;
      children: SwiftNode[];
    },
    context
  ) {
    renderer.appendLine(formatAccess(access, context));
    renderer.append(`protocol ${name} {`);
    renderer.indent();

    _renderSwift(renderer, children, { ...context, inProtocol: true });

    renderer.outdent();
    renderer.appendLine('}');
  },

  extension(
    renderer,
    {
      name,
      inherit = [],
      where = [],
      children,
    }: {
      name: string;
      inherit?: string[];
      where?: string[];
      children: SwiftNode[];
    },
    context
  ) {
    renderer.appendLine(`extension ${name}`);
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
    _renderSwift(renderer, children, context);
    renderer.outdent();
    renderer.appendLine('}');
  },

  typealias(
    renderer,
    {
      name,
      children,
      access,
    }: {
      name: string;
      children: SwiftNode[];
      access?: AccessLevel;
    },
    context
  ) {
    renderer.appendLine(formatAccess(access, context));
    renderer.append(`typealias ${name} = `);
    _renderSwift(renderer, children, { ...context, inline: true });
  },

  var(
    renderer,
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
    context
  ) {
    renderer.appendLine(formatAccess(access, context));
    renderer.append(`${isStatic ? 'static ' : ''}var ${name}: ${type}`);

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
  },

  init(
    renderer,
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
    },
    context
  ) {
    renderer.appendLine(formatAccess(access, context));
    renderer.append('init(');
    for (let i = 0; i < parameters.length; i++) {
      if (i !== 0) {
        renderer.append(', ');
      }
      _renderSwift(renderer, parameters[i], { ...context, inline: true });
    }
    renderer.append(')');
    if (throws) {
      renderer.append(' throws');
    }
    renderer.append(' {');
    renderer.indent();

    _renderSwift(renderer, children, context);

    renderer.outdent();
    renderer.appendLine('}');
  },

  function(
    renderer,
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
    },
    context
  ) {
    renderer.appendLine(formatAccess(access, context));
    renderer.append(`${isStatic ? 'static ' : ''}func ${name}(`);
    for (let i = 0; i < parameters.length; i++) {
      if (i !== 0) {
        renderer.append(', ');
      }
      _renderSwift(renderer, parameters[i], { ...context, inline: true });
    }
    renderer.append(`)`);

    if (returns) {
      renderer.append(` -> ${returns}`);
    }

    renderer.append(` {`);
    renderer.indent();

    _renderSwift(renderer, children, context);

    renderer.outdent();
    renderer.appendLine('}');
  },

  case(
    renderer,
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
    context
  ) {
    if (isDefault) {
      renderer.appendLine('default');
    } else {
      renderer.appendLine('case ');
      _renderSwift(renderer, name, { ...context, inline: true });

      if (parameters.length) {
        renderer.append('(');

        for (let i = 0; i < parameters.length; i++) {
          if (i !== 0) {
            renderer.append(', ');
          }
          _renderSwift(renderer, parameters[i], { ...context, inline: true });
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
        _renderSwift(renderer, children, { ...context, inline: true });
      }
    }
  },

  paramdecl(
    renderer,
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
    },
    context
  ) {
    if (label) {
      renderer.append(`${label} `);
    }
    renderer.append(`${name}: ${type}`);
    if (defaultValue) {
      renderer.append(' = ');
      _renderSwift(renderer, defaultValue, { ...context, inline: true });
    }
  },

  switch(
    renderer,
    {
      value,
      children,
    }: {
      value: SwiftNode;
      children: SwiftNode[];
    },
    context
  ) {
    renderer.appendLine('switch ');
    _renderSwift(renderer, value, { ...context, inline: true });
    renderer.append(' {');

    _renderSwift(renderer, children, { ...context, inSwitch: true });

    renderer.appendLine('}');
  },

  call(
    renderer,
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
    },
    context
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
      _renderSwift(renderer, parameters[i], { ...context, inline: !expanded });
    }

    if (expanded) {
      renderer.outdent();
      renderer.appendLine(')');
    } else {
      renderer.append(')');
    }
  },

  param(
    renderer,
    {
      label,
      children,
    }: {
      label?: string;
      children: SwiftNode[];
    },
    context
  ) {
    const text = `${label ? `${label}: ` : ''}`;
    if (context.inline) {
      renderer.append(text);
    } else {
      renderer.appendLine(text);
    }

    renderer.continueLine();
    _renderSwift(renderer, children, { ...context, inline: true });
  },

  available(
    renderer,
    {
      versions,
      children,
    }: {
      versions: string[];
      children: SwiftNode[];
    },
    context
  ) {
    renderer.appendLine(`@available(${versions.join(', ')}, *)`);
    _renderSwift(renderer, children, context);
  },

  compilecheck(
    renderer,
    {
      condition,
      children,
    }: {
      condition: SwiftNode;
      children: SwiftNode[];
    },
    context
  ) {
    renderer.appendLine('#if ');

    _renderSwift(renderer, condition, { ...context, inline: true });
    _renderSwift(renderer, children, context);

    renderer.appendLine('#endif');
  },

  literal(renderer, props: SwiftLiteralProps, context) {
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
  },
};

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
    if (element.type in builtins) {
      const renderFn = builtins[element.type];
      renderFn(renderer, element.props, context);
      return;
    }

    throw new Error(`Unrecognized Swift element type '${element.type}'`);
  } else {
    const rendered = element.type(element.props);
    if (!rendered) {
      return;
    }
    return _renderSwift(renderer, rendered, context);
  }
}

class Renderer {
  lines: string[];
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
      this.trimIfNeeded();
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
    this.trimIfNeeded();
    return this.lines.join('\n');
  }

  private trimIfNeeded() {
    if (!this.lines.length) {
      return;
    }

    const idx = this.lines.length - 1;
    this.lines[idx] = this.lines[idx].trimEnd();
  }
}

type AccessLevel = 'public' | 'internal' | 'fileprivate' | 'private';

type SwiftLiteralProps =
  | { string: string }
  | { int: number }
  | { bool: boolean }
  | { array: SwiftNode[]; expanded?: boolean }
  | { dict: [SwiftNode, SwiftNode][]; expanded?: boolean };

function formatAccess(
  access: AccessLevel | null | undefined,
  context: RenderContext
): string {
  if (context.inProtocol) {
    return '';
  }

  if (!access) {
    access = context.defaultAccessLevel;
  }

  if (!access) {
    return '';
  }

  return `${access} `;
}

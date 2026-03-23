class TreeItem {
  label: string;
  collapsibleState: number;
  contextValue?: string;
  tooltip?: string | object;
  description?: string;
  iconPath?: object;
  command?: object;

  constructor(label: string, collapsibleState: number = 0) {
    this.label = label;
    this.collapsibleState = collapsibleState;
  }
}

class ThemeIcon {
  id: string;
  constructor(id: string) {
    this.id = id;
  }
}

class MarkdownString {
  value: string;
  constructor(value: string) {
    this.value = value;
  }
}

const TreeItemCollapsibleState = {
  None: 0,
  Collapsed: 1,
  Expanded: 2,
};

class EventEmitter {
  private _listeners: Array<(e: unknown) => void> = [];

  get event() {
    return (listener: (e: unknown) => void) => {
      this._listeners.push(listener);
      return { dispose: jest.fn() };
    };
  }

  fire(e: unknown) {
    for (const l of this._listeners) {
      l(e);
    }
  }

  dispose() {
    this._listeners = [];
  }
}

const vscode = {
  window: {
    createOutputChannel: jest.fn(() => ({
      appendLine: jest.fn(),
      show: jest.fn(),
      dispose: jest.fn(),
    })),
    showInformationMessage: jest.fn(),
    showErrorMessage: jest.fn(),
    showWarningMessage: jest.fn(),
    showQuickPick: jest.fn(),
    showInputBox: jest.fn(),
    showTextDocument: jest.fn().mockResolvedValue(undefined),
    createStatusBarItem: jest.fn(() => ({
      text: '',
      command: '',
      show: jest.fn(),
      dispose: jest.fn(),
    })),
    createTreeView: jest.fn(() => ({ dispose: jest.fn() })),
    withProgress: jest.fn((_opts: unknown, task: () => Promise<unknown>) => task()),
  },
  commands: {
    registerCommand: jest.fn(),
  },
  workspace: {
    getConfiguration: jest.fn(() => ({
      get: jest.fn().mockReturnValue(''),
    })),
    findFiles: jest.fn().mockResolvedValue([]),
    openTextDocument: jest.fn().mockResolvedValue({}),
    workspaceFolders: undefined as { uri: { fsPath: string } }[] | undefined,
    fs: {
      readFile: jest.fn().mockResolvedValue(new Uint8Array()),
    },
    createFileSystemWatcher: jest.fn(() => ({
      onDidCreate: jest.fn().mockReturnValue({ dispose: jest.fn() }),
      onDidChange: jest.fn().mockReturnValue({ dispose: jest.fn() }),
      onDidDelete: jest.fn().mockReturnValue({ dispose: jest.fn() }),
      dispose: jest.fn(),
    })),
  },
  env: {
    openExternal: jest.fn(),
  },
  Uri: {
    parse: jest.fn((url: string) => ({ toString: () => url, fsPath: url })),
    file: jest.fn((path: string) => ({ toString: () => `file://${path}`, fsPath: path })),
  },
  ExtensionContext: jest.fn(),
  StatusBarAlignment: {
    Left: 1,
    Right: 2,
  },
  ProgressLocation: {
    Notification: 15,
    SourceControl: 1,
    Window: 10,
  },
  TreeItem,
  ThemeIcon,
  MarkdownString,
  TreeItemCollapsibleState,
  EventEmitter,
};

export = vscode;

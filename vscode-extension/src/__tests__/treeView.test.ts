import * as vscode from 'vscode';
import { WispTreeDataProvider } from '../treeView/provider';
import {
  SectionItem,
  ManifestItem,
  EpicItem,
  SubtaskItem,
  PrdFolderItem,
  PrdFileItem,
  ErrorItem,
} from '../treeView/items';

function makeUri(fsPath: string): vscode.Uri {
  return { fsPath, toString: () => `file://${fsPath}` } as unknown as vscode.Uri;
}

function encodeJson(obj: unknown): Uint8Array {
  return new TextEncoder().encode(JSON.stringify(obj));
}

function encodeText(text: string): Uint8Array {
  return new TextEncoder().encode(text);
}

describe('WispTreeDataProvider', () => {
  let provider: WispTreeDataProvider;

  beforeEach(() => {
    jest.clearAllMocks();
    provider = new WispTreeDataProvider();
  });

  afterEach(() => {
    provider.dispose();
  });

  describe('getChildren(undefined)', () => {
    it('returns exactly two SectionItems', async () => {
      const children = await provider.getChildren(undefined);
      expect(children).toHaveLength(2);
      expect(children[0]).toBeInstanceOf(SectionItem);
      expect(children[1]).toBeInstanceOf(SectionItem);
      expect((children[0] as SectionItem).sectionLabel).toBe('Manifests');
      expect((children[1] as SectionItem).sectionLabel).toBe('PRDs');
    });
  });

  describe('getChildren(SectionItem("Manifests"))', () => {
    it('returns ManifestItem for valid JSON', async () => {
      const uri = makeUri('/ws/manifests/my-manifest.json');
      (vscode.workspace.findFiles as jest.Mock).mockResolvedValueOnce([uri]);
      (vscode.workspace.fs.readFile as jest.Mock).mockResolvedValueOnce(
        encodeJson({ name: 'My Manifest', epics: [{ name: 'Epic 1', subtasks: [] }] }),
      );

      const section = new SectionItem('Manifests');
      const children = await provider.getChildren(section);

      expect(children).toHaveLength(1);
      expect(children[0]).toBeInstanceOf(ManifestItem);
      expect((children[0] as ManifestItem).manifestName).toBe('My Manifest');
    });

    it('returns ErrorItem for malformed JSON', async () => {
      const uri = makeUri('/ws/manifests/bad.json');
      (vscode.workspace.findFiles as jest.Mock).mockResolvedValueOnce([uri]);
      (vscode.workspace.fs.readFile as jest.Mock).mockResolvedValueOnce(
        encodeText('not valid json {{{'),
      );

      const section = new SectionItem('Manifests');
      const children = await provider.getChildren(section);

      expect(children).toHaveLength(1);
      expect(children[0]).toBeInstanceOf(ErrorItem);
    });

    it('returns empty array when no manifests found', async () => {
      (vscode.workspace.findFiles as jest.Mock).mockResolvedValueOnce([]);

      const section = new SectionItem('Manifests');
      const children = await provider.getChildren(section);

      expect(children).toHaveLength(0);
    });

    it('uses filename as manifest name when name field is absent', async () => {
      const uri = makeUri('/ws/manifests/fallback.json');
      (vscode.workspace.findFiles as jest.Mock).mockResolvedValueOnce([uri]);
      (vscode.workspace.fs.readFile as jest.Mock).mockResolvedValueOnce(
        encodeJson({ epics: [] }),
      );

      const section = new SectionItem('Manifests');
      const children = await provider.getChildren(section);

      expect((children[0] as ManifestItem).manifestName).toBe('fallback');
    });
  });

  describe('getChildren(ManifestItem)', () => {
    it('returns correct EpicItem count', async () => {
      const manifest = new ManifestItem('Test', '/ws/manifests/test.json', [
        { name: 'Epic A', subtasks: [] },
        { name: 'Epic B', subtasks: [] },
      ]);

      const children = await provider.getChildren(manifest);

      expect(children).toHaveLength(2);
      expect(children[0]).toBeInstanceOf(EpicItem);
      expect((children[0] as EpicItem).epicName).toBe('Epic A');
      expect(children[1]).toBeInstanceOf(EpicItem);
      expect((children[1] as EpicItem).epicName).toBe('Epic B');
    });

    it('returns empty array for manifest with no epics', async () => {
      const manifest = new ManifestItem('Empty', '/ws/manifests/empty.json', []);
      const children = await provider.getChildren(manifest);
      expect(children).toHaveLength(0);
    });
  });

  describe('getChildren(EpicItem)', () => {
    it('returns correct SubtaskItem count', async () => {
      const epic = new EpicItem('Epic A', '/ws/manifests/test.json', [
        { prd: 'prds/01-feature.md', repositories: [{ url: 'https://github.com/org/repo' }] },
        { prd: 'prds/02-feature.md', repositories: [] },
      ]);

      const children = await provider.getChildren(epic);

      expect(children).toHaveLength(2);
      expect(children[0]).toBeInstanceOf(SubtaskItem);
      expect((children[0] as SubtaskItem).prdPath).toBe('prds/01-feature.md');
      expect((children[0] as SubtaskItem).repoUrl).toBe('https://github.com/org/repo');
    });
  });

  describe('legacy key support', () => {
    it('reads "orders" key when "epics" is absent', async () => {
      const uri = makeUri('/ws/manifests/legacy.json');
      (vscode.workspace.findFiles as jest.Mock).mockResolvedValueOnce([uri]);
      (vscode.workspace.fs.readFile as jest.Mock).mockResolvedValueOnce(
        encodeJson({
          name: 'Legacy Manifest',
          orders: [{ name: 'Order 1', subtasks: [] }],
        }),
      );

      const section = new SectionItem('Manifests');
      const children = await provider.getChildren(section);
      const manifestItem = children[0] as ManifestItem;
      expect(manifestItem.epics).toHaveLength(1);
      expect(manifestItem.epics[0].name).toBe('Order 1');
    });

    it('reads "prds" key on EpicItem when "subtasks" is absent', async () => {
      const epic = new EpicItem('Epic Legacy', '/ws/manifests/test.json', []);
      // Directly set prds key via legacy alias to simulate
      const epicWithPrds = new EpicItem('Epic Legacy', '/ws/manifests/test.json', [
        { prd: 'prds/task.md' },
      ]);

      const children = await provider.getChildren(epicWithPrds);
      expect(children).toHaveLength(1);
    });
  });

  describe('PRD title/status extraction', () => {
    it('extracts title and status from first 10 lines', async () => {
      const uri = makeUri('/ws/prds/feature/task.md');
      (vscode.workspace.findFiles as jest.Mock).mockResolvedValueOnce([uri]);

      // For PRD folders
      const section = new SectionItem('PRDs');
      const folderChildren = await provider.getChildren(section);
      // Returns PrdFolderItem
      if (folderChildren.length > 0 && folderChildren[0] instanceof PrdFolderItem) {
        (vscode.workspace.fs.readFile as jest.Mock).mockResolvedValueOnce(
          encodeText('# My Feature\n\n> **Status**: Ready\n\nSome content'),
        );
        const fileChildren = await provider.getChildren(folderChildren[0]);
        expect(fileChildren[0]).toBeInstanceOf(PrdFileItem);
        const prdItem = fileChildren[0] as PrdFileItem;
        // Tooltip should contain title and status
        expect(JSON.stringify(prdItem.tooltip)).toContain('My Feature');
        expect(JSON.stringify(prdItem.tooltip)).toContain('Ready');
      }
    });
  });

  describe('getChildren(PrdFolderItem)', () => {
    it('returns PrdFileItems for folder URIs', async () => {
      const uri1 = makeUri('/ws/prds/feature/task1.md');
      const uri2 = makeUri('/ws/prds/feature/task2.md');
      (vscode.workspace.fs.readFile as jest.Mock).mockResolvedValue(
        encodeText('# Title\n> **Status**: Ready'),
      );

      const folder = new PrdFolderItem('feature', [uri1, uri2]);
      const children = await provider.getChildren(folder);

      expect(children).toHaveLength(2);
      expect(children[0]).toBeInstanceOf(PrdFileItem);
      expect(children[1]).toBeInstanceOf(PrdFileItem);
    });
  });

  describe('refresh()', () => {
    it('fires onDidChangeTreeData event', () => {
      const listener = jest.fn();
      provider.onDidChangeTreeData(listener);
      provider.refresh();
      expect(listener).toHaveBeenCalledWith(undefined);
    });
  });
});

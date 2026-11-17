import { useMemo, useState } from 'react';
import { Check, Copy, FileCode2, FileText, FolderOpen, Search } from 'lucide-react';
import type { ProjectFile } from '../types/project';

interface RepositoryViewProps {
  files: ProjectFile[];
}

const CATEGORIES = [
  'All',
  'Apex Services',
  'Apex Tests',
  'Apex Triggers',
  'LWC',
  'Custom Objects',
  'Flows',
  'Security & Metadata',
  'Documentation',
  'Scripts',
  'Project Config',
];

export default function RepositoryView({ files }: RepositoryViewProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedPath, setSelectedPath] = useState<string>(
    files.find((f) => f.path === 'force-app/main/default/classes/LoanManagementController.cls')?.path ||
      files[0]?.path ||
      ''
  );
  const [copied, setCopied] = useState(false);

  const filteredFiles = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return files.filter((file) => {
      const matchesCat = selectedCategory === 'All' || file.category === selectedCategory;
      const matchesQuery =
        !q ||
        file.path.toLowerCase().includes(q) ||
        file.name.toLowerCase().includes(q) ||
        file.category.toLowerCase().includes(q);
      return matchesCat && matchesQuery;
    });
  }, [files, selectedCategory, searchQuery]);

  const activeFile = useMemo(
    () => files.find((f) => f.path === selectedPath) || filteredFiles[0] || null,
    [files, filteredFiles, selectedPath]
  );

  const handleCopy = async () => {
    if (!activeFile) return;
    try {
      await navigator.clipboard.writeText(activeFile.content);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      // Clipboard API may be restricted in some contexts
    }
  };

  const formatBytes = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    return `${(bytes / 1024).toFixed(1)} KB`;
  };

  return (
    <div className="flex flex-col h-[calc(100vh-65px)]">
      {/* Filter & Search Toolbar */}
      <div className="border-b border-slate-200 bg-slate-50/70 px-6 py-3 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-1 overflow-x-auto pb-1 sm:pb-0">
          {CATEGORIES.map((cat) => {
            const isActive = selectedCategory === cat;
            return (
              <button
                key={cat}
                type="button"
                onClick={() => setSelectedCategory(cat)}
                className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                  isActive
                    ? 'bg-slate-900 text-white'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/70'
                }`}
              >
                {cat}
              </button>
            );
          })}
        </div>

        <div className="relative w-full sm:w-64 shrink-0">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Filter 116 SFDX files..."
            aria-label="Filter Salesforce DX files"
            className="w-full pl-9 pr-3 py-1.5 text-sm bg-white border border-slate-200 rounded-md text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0176D3]/30 focus:border-[#0176D3]"
          />
        </div>
      </div>

      {/* Main Split Workspace */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-[320px_1fr] min-h-0">
        {/* File List Sidebar */}
        <aside className="border-r border-slate-200 overflow-y-auto bg-white">
          <div className="px-4 py-2.5 border-b border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span className="font-medium text-slate-700">salesforce-collections-management</span>
            <span className="font-mono tabular-nums">{filteredFiles.length} files</span>
          </div>

          {filteredFiles.length === 0 ? (
            <div className="p-6 text-center text-sm text-slate-500">
              No files match your filter.
              <div className="mt-3">
                <button
                  type="button"
                  onClick={() => {
                    setSearchQuery('');
                    setSelectedCategory('All');
                  }}
                  className="text-xs font-medium text-[#0176D3] hover:underline cursor-pointer"
                >
                  Reset filters
                </button>
              </div>
            </div>
          ) : (
            <ul className="divide-y divide-slate-100">
              {filteredFiles.map((file) => {
                const isSelected = activeFile?.path === file.path;
                const isCode = ['cls', 'trigger', 'js', 'html', 'css', 'xml', 'apex', 'soql'].includes(file.ext);
                return (
                  <li key={file.path}>
                    <button
                      type="button"
                      onClick={() => setSelectedPath(file.path)}
                      className={`w-full text-left px-4 py-2.5 transition-colors cursor-pointer flex items-start gap-2.5 ${
                        isSelected ? 'bg-[#0176D3]/8 text-[#0176D3]' : 'hover:bg-slate-50 text-slate-700'
                      }`}
                    >
                      {isCode ? (
                        <FileCode2 className="w-4 h-4 mt-0.5 shrink-0 opacity-75" />
                      ) : (
                        <FileText className="w-4 h-4 mt-0.5 shrink-0 opacity-75" />
                      )}
                      <div className="min-w-0 flex-1">
                        <p className={`text-xs font-medium truncate ${isSelected ? 'text-[#0176D3]' : 'text-slate-900'}`}>
                          {file.name}
                        </p>
                        <p className="text-[11px] text-slate-500 truncate mt-0.5 font-mono">
                          {file.path}
                        </p>
                      </div>
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </aside>

        {/* Code Viewer */}
        <section className="flex flex-col min-w-0 min-h-0 bg-white">
          {activeFile ? (
            <>
              <div className="px-6 py-3 border-b border-slate-200 flex flex-wrap items-center justify-between gap-4 bg-white">
                <div className="min-w-0">
                  <div className="flex items-center gap-2 text-sm font-medium text-slate-900 font-mono truncate">
                    <FolderOpen className="w-4 h-4 text-slate-400 shrink-0" />
                    <span className="truncate">{activeFile.path}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
                    <span>{activeFile.category}</span>
                    <span aria-hidden="true">·</span>
                    <span className="font-mono tabular-nums">{activeFile.lines} lines</span>
                    <span aria-hidden="true">·</span>
                    <span className="font-mono tabular-nums">{formatBytes(activeFile.bytes)}</span>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={handleCopy}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-slate-700 bg-white border border-slate-200 rounded-md hover:bg-slate-50 transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                >
                  {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                  {copied ? 'Copied' : 'Copy Code'}
                </button>
              </div>

              <div className="flex-1 overflow-auto bg-slate-950 text-slate-100 p-5">
                <pre className="text-xs leading-6 font-mono">
                  {activeFile.content.split('\n').map((line, i) => (
                    <div key={i} className="table-row hover:bg-slate-900/80">
                      <span className="table-cell select-none pr-5 text-right text-slate-500 tabular-nums w-10">
                        {i + 1}
                      </span>
                      <span className="table-cell whitespace-pre">{line || ' '}</span>
                    </div>
                  ))}
                </pre>
              </div>
            </>
          ) : (
            <div className="flex-1 flex items-center justify-center text-sm text-slate-500">
              Select a file from the Salesforce DX repository to inspect its source code.
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

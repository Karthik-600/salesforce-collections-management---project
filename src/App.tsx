import { useState } from 'react';
import { Download } from 'lucide-react';
import projectFilesRaw from './data/projectFiles.json';
import type { ActiveTab, ProjectFile } from './types/project';
import RepositoryView from './components/RepositoryView';
import LwcPreviewView from './components/LwcPreviewView';
import DataModelFlowsView from './components/DataModelFlowsView';
import SetupGuideView from './components/SetupGuideView';

const projectFiles = projectFilesRaw as ProjectFile[];

const NAV_ITEMS: { id: ActiveTab; label: string }[] = [
  { id: 'repository', label: 'Repository' },
  { id: 'lwc', label: 'LWC Preview' },
  { id: 'model', label: 'Data Model' },
  { id: 'setup', label: 'Setup Guide' },
];

export default function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('repository');

  return (
    <div className="min-h-screen flex flex-col bg-white text-slate-900">
      {/* Strict 3-Zone Top Bar Contract */}
      <header className="sticky top-0 z-30 h-16 border-b border-slate-200 bg-white/95 backdrop-blur-xs px-6 flex items-center justify-between gap-8">
        <button
          type="button"
          onClick={() => setActiveTab('repository')}
          className="font-display text-base font-bold tracking-tight text-slate-900 whitespace-nowrap shrink-0 cursor-pointer"
        >
          Collections CRM SFDX
        </button>

        <nav className="flex items-center gap-6 overflow-x-auto" aria-label="Primary">
          {NAV_ITEMS.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setActiveTab(item.id)}
                className={`text-sm font-medium py-5 border-b-2 transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                  isActive
                    ? 'border-[#0176D3] text-slate-900'
                    : 'border-transparent text-slate-600 hover:text-slate-900'
                }`}
              >
                {item.label}
              </button>
            );
          })}
        </nav>

        <div className="flex items-center shrink-0">
          <a
            href="/salesforce-collections-management.zip"
            download="salesforce-collections-management.zip"
            className="inline-flex items-center gap-2 px-4 py-2 text-xs font-medium text-white bg-[#0176D3] rounded-md hover:bg-[#015ba3] transition-colors whitespace-nowrap shrink-0"
          >
            <Download className="w-3.5 h-3.5" />
            Download ZIP
          </a>
        </div>
      </header>

      <main className="flex-1">
        {activeTab === 'repository' && <RepositoryView files={projectFiles} />}
        {activeTab === 'lwc' && <LwcPreviewView />}
        {activeTab === 'model' && <DataModelFlowsView />}
        {activeTab === 'setup' && <SetupGuideView totalFiles={projectFiles.length} />}
      </main>
    </div>
  );
}

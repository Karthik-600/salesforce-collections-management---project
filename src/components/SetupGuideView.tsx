import { useState } from 'react';
import { Check, Copy, Download } from 'lucide-react';

interface SetupGuideViewProps {
  totalFiles: number;
}

const DEPLOY_COMMANDS = `# 1. Authenticate with your target Salesforce org
sf org login web --alias collections-dev

# 2. Deploy all Salesforce DX metadata
sf project deploy start --source-dir force-app --target-org collections-dev

# 3. Assign the Collections Manager Permission Set
sf org assign permset --name Collections_Manager_Access --target-org collections-dev

# 4. Run all local Apex tests with code coverage
sf apex run test --test-level RunLocalTests --result-format human --code-coverage --target-org collections-dev

# 5. (Optional) Seed sample Srinidhi Associates records
sf apex run --file scripts/apex/seedSampleData.apex --target-org collections-dev`;

const GITHUB_COMMANDS = `unzip salesforce-collections-management.zip
cd salesforce-collections-management
git init
git add .
git commit -m "feat: Salesforce CRM Collections Management reference implementation"
git branch -M main
git remote add origin https://github.com/<your-username>/salesforce-collections-management.git
git push -u origin main`;

export default function SetupGuideView({ totalFiles }: SetupGuideViewProps) {
  const [copiedBlock, setCopiedBlock] = useState<'deploy' | 'github' | null>(null);

  const copyText = async (text: string, key: 'deploy' | 'github') => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedBlock(key);
      setTimeout(() => setCopiedBlock(null), 1800);
    } catch {
      // ignore clipboard errors
    }
  };

  return (
    <div className="max-w-5xl mx-auto px-6 py-8 space-y-10">
      <div className="pb-6 border-b border-slate-200 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Deployment, Manual Configuration &amp; GitHub Guide
          </h1>
          <p className="text-sm text-slate-600 mt-1 max-w-2xl">
            Transparent breakdown of implemented Salesforce DX source ({totalFiles} files) versus org-level features requiring manual Salesforce administration.
          </p>
        </div>

        <a
          href="/salesforce-collections-management.zip"
          download="salesforce-collections-management.zip"
          className="inline-flex items-center gap-2 px-4 py-2 text-xs font-medium text-white bg-[#0176D3] rounded-md hover:bg-[#015ba3] transition-colors whitespace-nowrap shrink-0"
        >
          <Download className="w-4 h-4" />
          Download Project ZIP
        </a>
      </div>

      {/* Implemented vs Manual Matrix */}
      <section className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="border border-slate-200 rounded-lg p-5 bg-white">
          <h2 className="text-base font-bold text-slate-900">Implemented in Repository</h2>
          <p className="text-xs text-slate-500 mt-0.5 mb-4">Ready to deploy via Salesforce CLI (`sf project deploy start`)</p>
          <ul className="space-y-2.5 text-sm text-slate-700">
            <li>• 5 Custom Objects with 39 custom fields, 2 formula fields, and 5 validation rules (82 validated XML files).</li>
            <li>• 7 Apex classes (`LoanManagementController`, `LoanManagementService`, `TelecallerAssignmentService`, `RiskAnalysisService`, `SlackNotificationService`, `LoanClosureService`, `DailyCollectionSummaryInvocable`).</li>
            <li>• 2 Thin Apex Triggers (`PaymentTrigger`, `CollectionCaseTrigger`).</li>
            <li>• 6 Comprehensive Apex Test classes + `SlackHttpCalloutMock` covering positive, negative, null, overpayment, and 200-record bulk tests.</li>
            <li>• Complete `customerLoanDetails` Lightning Web Component bundle (HTML, JS, CSS, meta XML).</li>
            <li>• 5 Salesforce Flow metadata XML files, 3 Role-Based Permission Sets, 5 Tabs, Custom Labels, and Page Layout.</li>
            <li>• 10 Markdown documentation files (`README.md`, `FILE_MANIFEST.md`, and 8 guides in `docs/`).</li>
          </ul>
        </div>

        <div className="border border-slate-200 rounded-lg p-5 bg-slate-50/70">
          <h2 className="text-base font-bold text-slate-900">Requires Manual Org Configuration</h2>
          <p className="text-xs text-slate-500 mt-0.5 mb-4">Cannot be hardcoded or activated without org-specific credentials/licenses</p>
          <ul className="space-y-2.5 text-sm text-slate-700">
            <li>• <strong>Slack Named Credential</strong>: Update `Slack_Collections_Webhook` in Setup → Named Credentials with your real Slack Incoming Webhook or Bot Token.</li>
            <li>• <strong>Activate 5 Flows</strong>: Review timezone and activate each Draft Flow in Setup → Flow Builder.</li>
            <li>• <strong>Lightning App Builder</strong>: Place `customerLoanDetails` LWC onto the `Customer__c` Lightning Record Page and activate.</li>
            <li>• <strong>Einstein Prompt Builder</strong>: Requires Einstein Generative AI license; create and activate Flex Prompt Template `Collections_Loan_Risk_Analysis` (Rule-Based Fallback works immediately without it).</li>
            <li>• <strong>Management Dashboards</strong>: Create Loan Dashboard, Call Records, and Payment Dashboards in Reports &amp; Dashboards.</li>
            <li>• <strong>User Licensing &amp; Assignment</strong>: Assign `Telecaller_Access` and `Field_Executive_Access` permission sets to active users.</li>
          </ul>
        </div>
      </section>

      {/* Salesforce CLI Deploy Commands */}
      <section>
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-base font-bold text-slate-900">1. Deploy to Salesforce Org</h2>
          <button
            type="button"
            onClick={() => copyText(DEPLOY_COMMANDS, 'deploy')}
            className="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium text-slate-700 bg-white border border-slate-200 rounded-md hover:bg-slate-50 cursor-pointer"
          >
            {copiedBlock === 'deploy' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
            {copiedBlock === 'deploy' ? 'Copied' : 'Copy'}
          </button>
        </div>
        <pre className="p-4 bg-slate-950 text-slate-100 rounded-lg text-xs font-mono leading-6 overflow-x-auto">
          {DEPLOY_COMMANDS}
        </pre>
      </section>

      {/* GitHub Upload Commands */}
      <section>
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-base font-bold text-slate-900">2. Publish to GitHub Portfolio</h2>
          <button
            type="button"
            onClick={() => copyText(GITHUB_COMMANDS, 'github')}
            className="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium text-slate-700 bg-white border border-slate-200 rounded-md hover:bg-slate-50 cursor-pointer"
          >
            {copiedBlock === 'github' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
            {copiedBlock === 'github' ? 'Copied' : 'Copy'}
          </button>
        </div>
        <pre className="p-4 bg-slate-950 text-slate-100 rounded-lg text-xs font-mono leading-6 overflow-x-auto">
          {GITHUB_COMMANDS}
        </pre>
      </section>
    </div>
  );
}

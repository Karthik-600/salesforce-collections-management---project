import { useState } from 'react';
import { RefreshCw, AlertCircle } from 'lucide-react';

interface DemoCustomerRecord {
  id: string;
  name: string;
  phoneNumber: string;
  email: string;
  address: string;
  branch: string;
  state: string;
  contactabilityStatus: string;
  loans: {
    id: string;
    loanNumber: string;
    loanAmount: number;
    outstandingAmount: number;
    amountPaid: number;
    daysOverdue: number;
    loanStatus: string;
  }[];
  cases: {
    id: string;
    caseNumber: string;
    caseStatus: string;
    priority: string;
    assignedTelecallerName: string;
    nextFollowUpDate: string;
    collectionStatus: string;
  }[];
}

const INITIAL_RECORDS: DemoCustomerRecord[] = [
  {
    id: 'a01000000000001AAA',
    name: 'Suresh Babu',
    phoneNumber: '+91 98410 98765',
    email: 'suresh.babu@example.com',
    address: '18 MG Road, Indiranagar, Bengaluru 560038',
    branch: 'Bengaluru East',
    state: 'Karnataka',
    contactabilityStatus: 'Non-Contactable',
    loans: [
      {
        id: 'a02000000000001AAA',
        loanNumber: 'LN-0025',
        loanAmount: 750000,
        outstandingAmount: 690000,
        amountPaid: 60000,
        daysOverdue: 120,
        loanStatus: 'NPA',
      },
    ],
    cases: [
      {
        id: 'a03000000000001AAA',
        caseNumber: 'CC-00108',
        caseStatus: 'Escalated',
        priority: 'Critical',
        assignedTelecallerName: 'Divya Ramesh',
        nextFollowUpDate: '2026-11-18',
        collectionStatus: 'Non-Contactable',
      },
    ],
  },
  {
    id: 'a01000000000002AAA',
    name: 'Rajesh Kumar',
    phoneNumber: '+91 98400 12345',
    email: 'rajesh.kumar@example.com',
    address: '42 Anna Salai, Teynampet, Chennai 600018',
    branch: 'Chennai Central',
    state: 'Tamil Nadu',
    contactabilityStatus: 'Contactable',
    loans: [
      {
        id: 'a02000000000002AAA',
        loanNumber: 'LN-0041',
        loanAmount: 500000,
        outstandingAmount: 320000,
        amountPaid: 180000,
        daysOverdue: 45,
        loanStatus: 'Overdue',
      },
    ],
    cases: [
      {
        id: 'a03000000000002AAA',
        caseNumber: 'CC-00142',
        caseStatus: 'In Progress',
        priority: 'High',
        assignedTelecallerName: 'Arjun Menon',
        nextFollowUpDate: '2026-11-20',
        collectionStatus: 'Promise to Pay',
      },
    ],
  },
  {
    id: 'a01000000000003AAA',
    name: 'Karthik Subramanian',
    phoneNumber: '+91 94440 55112',
    email: 'karthik.s@example.com',
    address: '9 Race Course Road, Coimbatore 641018',
    branch: 'Coimbatore North',
    state: 'Tamil Nadu',
    contactabilityStatus: 'Contactable',
    loans: [
      {
        id: 'a02000000000003AAA',
        loanNumber: 'LN-0089',
        loanAmount: 300000,
        outstandingAmount: 50000,
        amountPaid: 250000,
        daysOverdue: 0,
        loanStatus: 'Active',
      },
    ],
    cases: [
      {
        id: 'a03000000000003AAA',
        caseNumber: 'CC-00201',
        caseStatus: 'Follow-Up Scheduled',
        priority: 'Low',
        assignedTelecallerName: 'Priya Nair',
        nextFollowUpDate: '2026-11-25',
        collectionStatus: 'Partial Payment',
      },
    ],
  },
];

function formatINR(amount: number) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);
}

function computeRisk(record: DemoCustomerRecord) {
  const loan = record.loans[0];
  if (!loan) return null;
  const activeCase = record.cases[0];

  const efficiency = loan.loanAmount > 0 ? Number(((loan.amountPaid / loan.loanAmount) * 100).toFixed(2)) : 0;
  const isNonContactable = ['Non-Contactable', 'Wrong Number', 'Switched Off'].includes(record.contactabilityStatus);
  const isEscalated = activeCase?.caseStatus === 'Escalated';

  let score = 0;
  if (loan.loanStatus !== 'Closed' && loan.outstandingAmount > 0) {
    if (loan.daysOverdue >= 90 || loan.loanStatus === 'NPA') score += 45;
    else if (loan.daysOverdue >= 30) score += 25;
    else if (loan.daysOverdue > 0) score += 10;

    if (efficiency < 25) score += 30;
    else if (efficiency < 60) score += 15;

    if (isNonContactable) score += 20;
    if (isEscalated) score += 15;
  }

  if (score >= 60) {
    return {
      riskLevel: 'HIGH' as const,
      efficiency,
      fieldVisitRequired: 'YES',
      tone: 'Firm, Compliance-Focused & Escalation-Ready',
      action:
        'Initiate immediate supervisor escalation, verify alternate contact numbers, and dispatch a Field Executive with GPS verification.',
      assessment: `Account ${loan.loanNumber} exhibits critical delinquency risk with ${loan.daysOverdue} days overdue and ${efficiency}% collection efficiency.\nOutstanding exposure stands at ${formatINR(loan.outstandingAmount)} against original principal of ${formatINR(loan.loanAmount)}.\nImmediate field intervention and structured settlement evaluation are strongly advised.`,
    };
  }
  if (score >= 30) {
    return {
      riskLevel: 'MEDIUM' as const,
      efficiency,
      fieldVisitRequired: isNonContactable ? 'YES' : 'NO',
      tone: 'Structured, Persuasive & Solution-Oriented',
      action:
        'Conduct structured telecalling follow-up to secure a dated Promise-to-Pay (PTP) or partial installment within 72 hours.',
      assessment: `Account ${loan.loanNumber} shows moderate delinquency pressure (${loan.daysOverdue} days overdue) with ${efficiency}% recovered to date.\nRemaining balance of ${formatINR(loan.outstandingAmount)} requires proactive cadence to prevent slippage into NPA.\nNegotiating a documented partial payment plan is the highest-yield recovery step.`,
    };
  }
  return {
    riskLevel: 'LOW' as const,
    efficiency,
    fieldVisitRequired: 'NO',
    tone: 'Courteous, Consultative & Relationship-Preserving',
    action: 'Send a polite payment reminder and confirm upcoming installment date via standard telecalling cadence.',
    assessment: `Account ${loan.loanNumber} is performing within acceptable recovery thresholds with ${efficiency}% collection efficiency.\nCurrent outstanding balance is ${formatINR(loan.outstandingAmount)} with ${loan.daysOverdue} days past due.\nRoutine reminder follow-up is sufficient; no field escalation is required at this time.`,
  };
}

export default function LwcPreviewView() {
  const [records, setRecords] = useState<DemoCustomerRecord[]>(INITIAL_RECORDS);
  const [selectedId, setSelectedId] = useState<string>(INITIAL_RECORDS[0].id);
  const [viewMode, setViewMode] = useState<'populated' | 'loading' | 'empty' | 'error'>('populated');
  const [paymentInput, setPaymentInput] = useState<string>('50000');
  const [paymentNotice, setPaymentNotice] = useState<string | null>(null);

  const selectedRecord = records.find((r) => r.id === selectedId) || records[0];
  const displayRecord: DemoCustomerRecord =
    viewMode === 'empty'
      ? { ...selectedRecord, loans: [], cases: [] }
      : selectedRecord;

  const risk = computeRisk(displayRecord);

  const handleSimulatePayment = () => {
    const amount = Number(paymentInput);
    const activeLoan = selectedRecord.loans[0];
    if (!activeLoan) return;
    if (!Number.isFinite(amount) || amount <= 0) {
      setPaymentNotice('Validation Error: Payment Amount must be greater than zero.');
      return;
    }
    if (amount > activeLoan.outstandingAmount) {
      setPaymentNotice(
        `LoanServiceException: Payment (${formatINR(amount)}) exceeds outstanding balance (${formatINR(activeLoan.outstandingAmount)}).`
      );
      return;
    }

    const newOutstanding = Math.max(0, activeLoan.outstandingAmount - amount);
    const newPaid = activeLoan.amountPaid + amount;
    const isNowClosed = newOutstanding === 0;

    setRecords((prev) =>
      prev.map((rec) => {
        if (rec.id !== selectedRecord.id) return rec;
        return {
          ...rec,
          loans: rec.loans.map((l, idx) =>
            idx === 0
              ? {
                  ...l,
                  amountPaid: newPaid,
                  outstandingAmount: newOutstanding,
                  loanStatus: isNowClosed ? 'Closed' : l.loanStatus,
                }
              : l
          ),
          cases: isNowClosed
            ? rec.cases.map((c) => ({
                ...c,
                caseStatus: 'Closed',
                collectionStatus: 'Recovered',
              }))
            : rec.cases,
        };
      })
    );

    setPaymentNotice(
      isNowClosed
        ? `LoanManagementService + LoanClosureService executed: Outstanding reached ₹0 — Loan ${activeLoan.loanNumber} and associated Collection Case auto-closed.`
        : `LoanManagementService executed: Recorded ${formatINR(amount)} payment. Remaining outstanding updated to ${formatINR(newOutstanding)}.`
    );
  };

  const handleResetDemo = () => {
    setRecords(INITIAL_RECORDS);
    setPaymentNotice(null);
    setViewMode('populated');
  };

  return (
    <div className="max-w-6xl mx-auto px-6 py-8">
      <div className="flex flex-wrap items-end justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Interactive LWC Preview: customerLoanDetails
          </h1>
          <p className="text-sm text-slate-600 mt-1 max-w-2xl">
            Simulated Salesforce Lightning Record Page preview mirroring <span className="font-mono text-slate-800">customerLoanDetails.html</span>,{' '}
            <span className="font-mono text-slate-800">LoanManagementController</span>, and <span className="font-mono text-slate-800">RiskAnalysisService</span>.
          </p>
        </div>

        <button
          type="button"
          onClick={handleResetDemo}
          className="px-3.5 py-2 text-xs font-medium text-slate-700 bg-white border border-slate-200 rounded-md hover:bg-slate-50 transition-colors cursor-pointer whitespace-nowrap shrink-0"
        >
          Reset Sample Data
        </button>
      </div>

      {/* Controls Bar */}
      <div className="py-4 flex flex-wrap items-center justify-between gap-4 border-b border-slate-200">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-xs font-medium text-slate-500 mr-1">Customer Record:</span>
          {records.map((rec) => {
            const active = rec.id === selectedRecord.id;
            return (
              <button
                key={rec.id}
                type="button"
                onClick={() => {
                  setSelectedId(rec.id);
                  setViewMode('populated');
                  setPaymentNotice(null);
                }}
                className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors cursor-pointer whitespace-nowrap shrink-0 ${
                  active ? 'bg-[#0176D3] text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                }`}
              >
                {rec.name} ({rec.loans[0]?.loanStatus})
              </button>
            );
          })}
        </div>

        <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-md">
          {(['populated', 'loading', 'empty', 'error'] as const).map((mode) => (
            <button
              key={mode}
              type="button"
              onClick={() => setViewMode(mode)}
              className={`px-2.5 py-1 text-xs font-medium rounded transition-colors capitalize cursor-pointer whitespace-nowrap shrink-0 ${
                viewMode === mode ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              {mode}
            </button>
          ))}
        </div>
      </div>

      {/* Simulated Payment Trigger Tester */}
      {viewMode === 'populated' && selectedRecord.loans[0] && selectedRecord.loans[0].outstandingAmount > 0 && (
        <div className="my-5 p-4 bg-slate-50 border border-slate-200 rounded-lg flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-xs font-semibold text-slate-900">
              Test PaymentTrigger &amp; LoanClosureService
            </p>
            <p className="text-xs text-slate-600 mt-0.5">
              Enter a payment amount (or full payoff {formatINR(selectedRecord.loans[0].outstandingAmount)}) to see real-time balance recalculation and auto-closure.
            </p>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="number"
              min="1"
              value={paymentInput}
              onChange={(e) => setPaymentInput(e.target.value)}
              aria-label="Simulated payment amount in INR"
              className="w-36 px-3 py-1.5 text-xs font-mono tabular-nums bg-white border border-slate-300 rounded-md text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0176D3]/30 focus:border-[#0176D3]"
            />
            <button
              type="button"
              onClick={handleSimulatePayment}
              className="px-3.5 py-1.5 text-xs font-medium text-white bg-[#0176D3] rounded-md hover:bg-[#015ba3] transition-colors cursor-pointer whitespace-nowrap shrink-0"
            >
              Simulate Payment
            </button>
          </div>
        </div>
      )}

      {paymentNotice && (
        <div className="mb-5 px-4 py-3 text-xs text-slate-800 bg-slate-50 border border-slate-300 rounded-md">
          {paymentNotice}
        </div>
      )}

      {/* SLDS Lightning Card Frame */}
      <div className="mt-4 bg-white border border-slate-200 rounded-lg overflow-hidden">
        {/* Card Header */}
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between gap-4 bg-slate-50/50">
          <div>
            <h2 className="text-base font-bold text-slate-900">
              Customer Loan &amp; Collection Workspace
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-mono">
              c-customer-loan-details · recordId: {selectedRecord.id}
            </p>
          </div>
          <button
            type="button"
            onClick={() => {
              setViewMode('loading');
              setTimeout(() => setViewMode('populated'), 450);
            }}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-slate-700 bg-white border border-slate-200 rounded-md hover:bg-slate-50 transition-colors cursor-pointer whitespace-nowrap shrink-0"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${viewMode === 'loading' ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>

        {/* Card Body */}
        <div className="p-6">
          {viewMode === 'loading' && (
            <div className="py-16 flex flex-col items-center justify-center text-slate-500 gap-3">
              <RefreshCw className="w-6 h-6 animate-spin text-[#0176D3]" />
              <p className="text-sm">Loading customer collection details...</p>
            </div>
          )}

          {viewMode === 'error' && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-md flex items-start gap-3 text-red-800">
              <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-semibold">AuraHandledException</p>
                <p className="text-xs mt-1">
                  Insufficient permissions to view customer collection records. Assign Telecaller_Access or Collections_Manager_Access permission set.
                </p>
              </div>
            </div>
          )}

          {(viewMode === 'populated' || viewMode === 'empty') && (
            <div className="space-y-8">
              {/* SECTION 1: CUSTOMER DETAILS */}
              <section className="pb-6 border-b border-slate-200">
                <div className="flex items-baseline justify-between mb-4">
                  <h3 className="text-sm font-semibold text-slate-900">1. Customer Details</h3>
                  <span className="text-xs text-slate-500">
                    Contactability: <strong className="text-slate-800 font-medium">{displayRecord.contactabilityStatus}</strong>
                  </span>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div>
                    <p className="text-xs text-slate-500">Customer Name</p>
                    <p className="text-sm font-semibold text-slate-900 mt-0.5">{displayRecord.name}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Phone Number</p>
                    <p className="text-sm font-semibold text-[#0176D3] font-mono tabular-nums mt-0.5">{displayRecord.phoneNumber}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Email</p>
                    <p className="text-sm font-medium text-slate-900 mt-0.5">{displayRecord.email}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Branch / State</p>
                    <p className="text-sm font-medium text-slate-900 mt-0.5">{displayRecord.branch}, {displayRecord.state}</p>
                  </div>
                  <div className="sm:col-span-2 lg:col-span-4">
                    <p className="text-xs text-slate-500">Address</p>
                    <p className="text-sm text-slate-800 mt-0.5">{displayRecord.address}</p>
                  </div>
                </div>
              </section>

              {/* SECTION 2: LOAN DETAILS */}
              <section className="pb-6 border-b border-slate-200">
                <div className="flex items-baseline justify-between mb-4">
                  <h3 className="text-sm font-semibold text-slate-900">2. Loan Details</h3>
                  <span className="text-xs text-slate-500 font-mono tabular-nums">
                    {displayRecord.loans.length} {displayRecord.loans.length === 1 ? 'Account' : 'Accounts'}
                  </span>
                </div>
                {displayRecord.loans.length > 0 ? (
                  displayRecord.loans.map((loan) => (
                    <div key={loan.id} className="p-4 bg-slate-50 border border-slate-200 rounded-md grid grid-cols-2 md:grid-cols-5 gap-4">
                      <div>
                        <p className="text-xs text-slate-500">Loan Number</p>
                        <p className="text-sm font-semibold font-mono text-slate-900 mt-0.5">{loan.loanNumber}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Total Loan Amount</p>
                        <p className="text-sm font-semibold font-mono tabular-nums text-slate-900 mt-0.5">{formatINR(loan.loanAmount)}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Outstanding Amount</p>
                        <p className="text-sm font-bold font-mono tabular-nums text-red-700 mt-0.5">{formatINR(loan.outstandingAmount)}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Amount Paid</p>
                        <p className="text-sm font-semibold font-mono tabular-nums text-emerald-700 mt-0.5">{formatINR(loan.amountPaid)}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Loan Status</p>
                        <p className="text-sm font-semibold text-slate-900 mt-0.5">{loan.loanStatus}</p>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-4 bg-slate-50 border border-dashed border-slate-300 rounded-md text-xs text-slate-600">
                    No loan accounts are currently linked to this customer.
                  </div>
                )}
              </section>

              {/* SECTION 3: COLLECTION CASE */}
              <section className="pb-6 border-b border-slate-200">
                <div className="flex items-baseline justify-between mb-4">
                  <h3 className="text-sm font-semibold text-slate-900">3. Collection Case</h3>
                  <span className="text-xs text-slate-500 font-mono tabular-nums">
                    {displayRecord.cases.length} {displayRecord.cases.length === 1 ? 'Case' : 'Cases'}
                  </span>
                </div>
                {displayRecord.cases.length > 0 ? (
                  displayRecord.cases.map((c) => (
                    <div key={c.id} className="p-4 bg-slate-50 border border-slate-200 rounded-md grid grid-cols-2 md:grid-cols-5 gap-4">
                      <div>
                        <p className="text-xs text-slate-500">Case Number</p>
                        <p className="text-sm font-semibold font-mono text-slate-900 mt-0.5">{c.caseNumber}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Case Status</p>
                        <p className="text-sm font-semibold text-slate-900 mt-0.5">{c.caseStatus}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Priority</p>
                        <p className="text-sm font-semibold text-slate-900 mt-0.5">{c.priority}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Assigned Telecaller</p>
                        <p className="text-sm font-medium text-slate-900 mt-0.5">{c.assignedTelecallerName}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Next Follow-Up Date</p>
                        <p className="text-sm font-mono tabular-nums text-slate-900 mt-0.5">{c.nextFollowUpDate}</p>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-4 bg-slate-50 border border-dashed border-slate-300 rounded-md text-xs text-slate-600">
                    No active collection cases found for this customer.
                  </div>
                )}
              </section>

              {/* SECTION 4: RISK INDICATOR */}
              <section>
                <div className="flex items-baseline justify-between mb-4">
                  <h3 className="text-sm font-semibold text-slate-900">4. Risk Indicator &amp; Recovery Guidance</h3>
                  {risk && (
                    <span className="text-xs text-slate-500">
                      Source: Rule-Based Fallback (Einstein Prompt Builder optional)
                    </span>
                  )}
                </div>
                {risk ? (
                  <div className="p-4 bg-slate-50 border border-slate-200 rounded-md space-y-4">
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div>
                        <p className="text-xs text-slate-500">Risk Classification</p>
                        <p
                          className={`text-sm font-bold mt-0.5 ${
                            risk.riskLevel === 'HIGH'
                              ? 'text-red-700'
                              : risk.riskLevel === 'MEDIUM'
                              ? 'text-amber-700'
                              : 'text-emerald-700'
                          }`}
                        >
                          {risk.riskLevel} RISK
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Collection Efficiency</p>
                        <p className="text-sm font-semibold font-mono tabular-nums text-slate-900 mt-0.5">
                          {risk.efficiency}%
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Field Visit Required</p>
                        <p className="text-sm font-semibold text-slate-900 mt-0.5">{risk.fieldVisitRequired}</p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500">Suggested Tone</p>
                        <p className="text-sm font-medium text-slate-900 mt-0.5">{risk.tone}</p>
                      </div>
                    </div>

                    <div className="pt-3 border-t border-slate-200">
                      <p className="text-xs text-slate-500">3-Line Professional Assessment</p>
                      <p className="text-sm text-slate-800 whitespace-pre-line leading-relaxed mt-1">
                        {risk.assessment}
                      </p>
                    </div>

                    <div className="pt-3 border-t border-slate-200">
                      <p className="text-xs text-slate-500">Recommended Telecaller Action</p>
                      <p className="text-sm font-medium text-slate-900 mt-1">{risk.action}</p>
                    </div>
                  </div>
                ) : (
                  <div className="p-4 bg-slate-50 border border-dashed border-slate-300 rounded-md text-xs text-slate-600">
                    Risk indicator will appear once at least one Loan Account is associated with this customer.
                  </div>
                )}
              </section>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

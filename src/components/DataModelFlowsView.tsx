import { useState } from 'react';

interface ObjectSchema {
  apiName: string;
  label: string;
  sharing: string;
  nameField: string;
  validationRule: string;
  fields: { api: string; type: string; req: string; notes: string }[];
}

const OBJECTS: ObjectSchema[] = [
  {
    apiName: 'Customer__c',
    label: 'Customer',
    sharing: 'ReadWrite',
    nameField: 'Name (Text)',
    validationRule: 'Require_Valid_Phone_Length (LEN >= 10)',
    fields: [
      { api: 'Phone_Number__c', type: 'Phone', req: 'Required', notes: 'History tracked' },
      { api: 'Email__c', type: 'Email', req: 'Optional', notes: 'Customer email address' },
      { api: 'Address__c', type: 'LongTextArea(1000)', req: 'Optional', notes: 'Residential / business address' },
      { api: 'State__c', type: 'Picklist', req: 'Optional', notes: 'Tamil Nadu, Karnataka, Maharashtra, Telangana, etc.' },
      { api: 'Branch__c', type: 'Text(100)', req: 'Optional', notes: 'Operating agency branch' },
      { api: 'Contactability_Status__c', type: 'Picklist', req: 'Optional', notes: 'Contactable, Non-Contactable, Switched Off, Wrong Number, Pending Verification' },
    ],
  },
  {
    apiName: 'Loan_Account__c',
    label: 'Loan Account',
    sharing: 'ControlledByParent',
    nameField: 'Name (AutoNumber: LN-{0000})',
    validationRule: 'Non_Negative_Balances (Loan > 0, Balances >= 0)',
    fields: [
      { api: 'Customer__c', type: 'MasterDetail(Customer__c)', req: 'Required', notes: 'Parent customer relationship' },
      { api: 'Loan_Amount__c', type: 'Currency(16,2)', req: 'Required', notes: 'Original principal amount' },
      { api: 'Outstanding_Amount__c', type: 'Currency(16,2)', req: 'Required', notes: 'Remaining unpaid balance; history tracked' },
      { api: 'Amount_Paid__c', type: 'Currency(16,2)', req: 'Default 0', notes: 'Cumulative recovered amount' },
      { api: 'Interest_Rate__c', type: 'Percent(5,2)', req: 'Optional', notes: 'Annual interest rate' },
      { api: 'Due_Date__c', type: 'Date', req: 'Required', notes: 'Installment / maturity due date' },
      { api: 'Loan_Status__c', type: 'Picklist', req: 'Default Active', notes: 'Active, Overdue, NPA, Settled, Closed' },
      { api: 'Risk_Level__c', type: 'Picklist', req: 'Default LOW', notes: 'LOW, MEDIUM, HIGH' },
      { api: 'Collection_Efficiency__c', type: 'Formula (Percent)', req: 'Calculated', notes: 'Amount_Paid__c / Loan_Amount__c' },
      { api: 'Days_Overdue__c', type: 'Formula (Number)', req: 'Calculated', notes: 'TODAY() - Due_Date__c when open' },
    ],
  },
  {
    apiName: 'Collection_Case__c',
    label: 'Collection Case',
    sharing: 'Private',
    nameField: 'Name (AutoNumber: CC-{00000})',
    validationRule: 'Require_Escalation_Reason (Required when Case_Status__c = Escalated)',
    fields: [
      { api: 'Customer__c', type: 'Lookup(Customer__c)', req: 'Required', notes: 'Restrict delete' },
      { api: 'Loan_Account__c', type: 'Lookup(Loan_Account__c)', req: 'Required', notes: 'Restrict delete' },
      { api: 'Assigned_Telecaller__c', type: 'Lookup(User)', req: 'Auto-Assigned', notes: 'Populated by TelecallerAssignmentService' },
      { api: 'Assigned_Field_Executive__c', type: 'Lookup(User)', req: 'Optional', notes: 'Field recovery officer' },
      { api: 'Case_Status__c', type: 'Picklist', req: 'Default New', notes: 'New, In Progress, Follow-Up Scheduled, Field Visit Requested, Escalated, Closed' },
      { api: 'Priority__c', type: 'Picklist', req: 'Default Medium', notes: 'Low, Medium, High, Critical' },
      { api: 'Escalation_Reason__c', type: 'LongTextArea(1000)', req: 'Conditional', notes: 'Mandatory when Escalated' },
      { api: 'Next_Follow_Up_Date__c', type: 'Date', req: 'Optional', notes: 'Scheduled next telecaller call' },
      { api: 'Collection_Status__c', type: 'Picklist', req: 'Default Pending', notes: 'Pending, Partial Payment, Promise to Pay, Non-Contactable, Recovered, Settled' },
    ],
  },
  {
    apiName: 'Payment__c',
    label: 'Payment',
    sharing: 'ControlledByParent',
    nameField: 'Name (AutoNumber: PAY-{00000})',
    validationRule: 'Positive_Payment_Amount (Payment_Amount__c > 0)',
    fields: [
      { api: 'Loan_Account__c', type: 'MasterDetail(Loan_Account__c)', req: 'Required', notes: 'Parent loan account' },
      { api: 'Customer__c', type: 'Lookup(Customer__c)', req: 'Required', notes: 'Paying customer' },
      { api: 'Payment_Amount__c', type: 'Currency(16,2)', req: 'Required', notes: 'Must be strictly > 0' },
      { api: 'Payment_Date__c', type: 'Date', req: 'Default TODAY()', notes: 'Date of receipt' },
      { api: 'Payment_Mode__c', type: 'Picklist', req: 'Required', notes: 'Cash, UPI, NEFT/RTGS, Cheque, Bank Transfer, Card' },
      { api: 'Payment_Status__c', type: 'Picklist', req: 'Required', notes: 'Pending, Success, Failed, Reversed' },
    ],
  },
  {
    apiName: 'Field_Visit__c',
    label: 'Field Visit',
    sharing: 'Private',
    nameField: 'Name (AutoNumber: FV-{00000})',
    validationRule: 'Valid_GPS_Coordinates (Lat -90..90, Lng -180..180)',
    fields: [
      { api: 'Customer__c', type: 'Lookup(Customer__c)', req: 'Required', notes: 'Visited customer' },
      { api: 'Loan_Account__c', type: 'Lookup(Loan_Account__c)', req: 'Required', notes: 'Associated loan' },
      { api: 'Assigned_Executive__c', type: 'Lookup(User)', req: 'Optional', notes: 'Field executive performing visit' },
      { api: 'Visit_Date__c', type: 'DateTime', req: 'Required', notes: 'Timestamp of site visit' },
      { api: 'GPS_Latitude__c', type: 'Number(9,6)', req: 'Optional', notes: 'Geo-tag latitude' },
      { api: 'GPS_Longitude__c', type: 'Number(9,6)', req: 'Optional', notes: 'Geo-tag longitude' },
      { api: 'Visit_Status__c', type: 'Picklist', req: 'Default Scheduled', notes: 'Scheduled, Completed, Customer Unavailable, Address Not Found, Cancelled' },
      { api: 'Visit_Notes__c', type: 'LongTextArea(2000)', req: 'Optional', notes: 'Photos stored via Salesforce Files' },
    ],
  },
];

const FLOWS = [
  {
    name: 'Case_Escalation_Slack_Alert',
    type: 'Record-Triggered (After Save)',
    trigger: 'Collection_Case__c · Case_Status__c = Escalated',
    action: 'SlackNotificationService → #collection-manager-alerts',
  },
  {
    name: 'Daily_Collection_Summary_Slack',
    type: 'Scheduled Flow (Daily 18:00)',
    trigger: 'Runs daily at 6:00 PM',
    action: 'DailyCollectionSummaryInvocable → #daily-collection-summary',
  },
  {
    name: 'Payment_Processing_Auto_Update',
    type: 'Record-Triggered (After Save)',
    trigger: 'Payment__c · Payment_Status__c = Success',
    action: 'LoanClosureService (paired with PaymentTrigger balance update)',
  },
  {
    name: 'Loan_Auto_Closure',
    type: 'Record-Triggered (After Save)',
    trigger: 'Loan_Account__c · Outstanding_Amount__c <= 0 & Status != Closed',
    action: 'LoanClosureService → closes Loan & open Collection Cases',
  },
  {
    name: 'Field_Visit_Tracking_Notification',
    type: 'Record-Triggered (After Save)',
    trigger: 'Field_Visit__c · Create & Update',
    action: 'SlackNotificationService → #field-executive-updates',
  },
];

export default function DataModelFlowsView() {
  const [selectedObj, setSelectedObj] = useState<string>(OBJECTS[0].apiName);
  const current = OBJECTS.find((o) => o.apiName === selectedObj) || OBJECTS[0];

  return (
    <div className="max-w-6xl mx-auto px-6 py-8 space-y-10">
      {/* Data Model Section */}
      <section>
        <div className="pb-5 border-b border-slate-200">
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Salesforce Data Model &amp; Automation
          </h1>
          <p className="text-sm text-slate-600 mt-1">
            Five custom objects with Master-Detail and Lookup integrity, formula KPIs, validation rules, and five Flow Builder automations.
          </p>
        </div>

        <div className="mt-5 flex flex-wrap items-center gap-1.5">
          {OBJECTS.map((obj) => (
            <button
              key={obj.apiName}
              type="button"
              onClick={() => setSelectedObj(obj.apiName)}
              className={`px-3.5 py-2 text-xs font-medium rounded-md transition-colors cursor-pointer font-mono whitespace-nowrap shrink-0 ${
                selectedObj === obj.apiName
                  ? 'bg-slate-900 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              {obj.apiName}
            </button>
          ))}
        </div>

        <div className="mt-4 border border-slate-200 rounded-lg overflow-hidden bg-white">
          <div className="px-5 py-4 border-b border-slate-200 bg-slate-50/70 flex flex-wrap items-center justify-between gap-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">
                {current.label} <span className="font-mono font-normal text-slate-500 text-sm">({current.apiName})</span>
              </h2>
              <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500 mt-1">
                <span>Name Field: {current.nameField}</span>
                <span aria-hidden="true">·</span>
                <span>Sharing: {current.sharing}</span>
                <span aria-hidden="true">·</span>
                <span>Validation: {current.validationRule}</span>
              </div>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-200 text-xs font-semibold text-slate-500 bg-white">
                  <th className="py-3 px-5">Field API Name</th>
                  <th className="py-3 px-5">Data Type</th>
                  <th className="py-3 px-5">Requirement</th>
                  <th className="py-3 px-5">Details / Picklist Values</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {current.fields.map((f) => (
                  <tr key={f.api} className="hover:bg-slate-50/70">
                    <td className="py-2.5 px-5 font-mono text-xs font-medium text-slate-900">{f.api}</td>
                    <td className="py-2.5 px-5 font-mono text-xs text-slate-700">{f.type}</td>
                    <td className="py-2.5 px-5 text-xs text-slate-600">{f.req}</td>
                    <td className="py-2.5 px-5 text-xs text-slate-600">{f.notes}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Flows Section */}
      <section>
        <div className="mb-4">
          <h2 className="text-lg font-bold text-slate-900">Salesforce Flows &amp; Slack Routing</h2>
          <p className="text-xs text-slate-600 mt-0.5">
            All 5 Flow XML files are deployed in Draft status so administrators can verify the Slack Named Credential before activating.
          </p>
        </div>

        <div className="border border-slate-200 rounded-lg overflow-hidden bg-white">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-200 text-xs font-semibold text-slate-500 bg-slate-50/70">
                  <th className="py-3 px-5">Flow API Name</th>
                  <th className="py-3 px-5">Flow Type</th>
                  <th className="py-3 px-5">Trigger / Schedule</th>
                  <th className="py-3 px-5">Action &amp; Channel</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {FLOWS.map((flow) => (
                  <tr key={flow.name} className="hover:bg-slate-50/70">
                    <td className="py-3 px-5 font-mono text-xs font-medium text-slate-900">{flow.name}</td>
                    <td className="py-3 px-5 text-xs text-slate-700">{flow.type}</td>
                    <td className="py-3 px-5 text-xs text-slate-600">{flow.trigger}</td>
                    <td className="py-3 px-5 font-mono text-xs text-[#0176D3]">{flow.action}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>
  );
}

# Project File Manifest

This manifest lists all generated modules in `salesforce-collections-management/`, their locations, purposes, dependencies, and implementation status (distinguishing implemented code from components requiring manual Salesforce org configuration).

| Category | Filename | Location | Purpose | Dependencies | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Config | `sfdx-project.json` | `/` | Salesforce DX project manifest (API v61.0) | Salesforce CLI | Implemented |
| Config | `.gitignore` | `/` | Excludes `.sf/`, secrets, logs, `node_modules/` | Git | Implemented |
| Object | `Customer__c` (+ 6 fields, 1 validation rule) | `force-app/main/default/objects/Customer__c/` | Borrower profile & contactability | None | Implemented |
| Object | `Loan_Account__c` (+ 10 fields, 1 validation rule) | `force-app/main/default/objects/Loan_Account__c/` | Loan principal, outstanding, paid, formulas | `Customer__c` | Implemented |
| Object | `Collection_Case__c` (+ 9 fields, 1 validation rule) | `force-app/main/default/objects/Collection_Case__c/` | Telecaller/field case tracking & escalation | `Customer__c`, `Loan_Account__c`, `User` | Implemented |
| Object | `Payment__c` (+ 6 fields, 1 validation rule) | `force-app/main/default/objects/Payment__c/` | Payment recording & status tracking | `Loan_Account__c`, `Customer__c` | Implemented |
| Object | `Field_Visit__c` (+ 8 fields, 1 validation rule) | `force-app/main/default/objects/Field_Visit__c/` | GPS-tagged field visits & notes | `Customer__c`, `Loan_Account__c`, `User` | Implemented |
| Apex | `LoanManagementController.cls` | `force-app/main/default/classes/` | Consolidated LWC Apex controller | Objects, `RiskAnalysisService` | Implemented |
| Apex | `LoanManagementService.cls` | `force-app/main/default/classes/` | Bulk-safe payment & balance logic | `Loan_Account__c`, `Payment__c`, `LoanClosureService` | Implemented |
| Apex | `TelecallerAssignmentService.cls` | `force-app/main/default/classes/` | Active-only Least-Loaded / Round-Robin assignment | `Collection_Case__c`, `User`, `Telecaller_Access` | Implemented |
| Apex | `RiskAnalysisService.cls` | `force-app/main/default/classes/` | Rule-based fallback + Einstein Prompt Builder input | `Loan_Account__c`, `Customer__c`, `Collection_Case__c` | Hybrid (Fallback Implemented; Einstein Manual Setup) |
| Apex | `SlackNotificationService.cls` | `force-app/main/default/classes/` | Invocable + Queueable Slack HTTP callouts | `Slack_Collections_Webhook` Named Credential | Implemented (Requires Org Named Credential URL) |
| Apex | `LoanClosureService.cls` | `force-app/main/default/classes/` | Zero-balance verification & auto-closure | `Loan_Account__c`, `Collection_Case__c` | Implemented |
| Apex | `DailyCollectionSummaryInvocable.cls` | `force-app/main/default/classes/` | Aggregates daily case counts for 6 PM Flow | `Collection_Case__c`, `SlackNotificationService` | Implemented |
| Apex Test | `SlackHttpCalloutMock.cls` | `force-app/main/default/classes/` | HTTP callout mock for Slack tests | None | Implemented |
| Apex Test | `LoanManagementControllerTest.cls` | `force-app/main/default/classes/` | Controller positive/negative/empty tests | `LoanManagementController` | Implemented |
| Apex Test | `LoanManagementServiceTest.cls` | `force-app/main/default/classes/` | Payment, overpayment, 200-record bulk tests | `LoanManagementService`, `PaymentTrigger` | Implemented |
| Apex Test | `TelecallerAssignmentServiceTest.cls` | `force-app/main/default/classes/` | Assignment strategy & bulk tests | `TelecallerAssignmentService`, `CollectionCaseTrigger` | Implemented |
| Apex Test | `RiskAnalysisServiceTest.cls` | `force-app/main/default/classes/` | LOW/MEDIUM/HIGH risk & Einstein map tests | `RiskAnalysisService` | Implemented |
| Apex Test | `SlackNotificationServiceTest.cls` | `force-app/main/default/classes/` | Mocked Slack callout & daily summary tests | `SlackNotificationService`, `SlackHttpCalloutMock` | Implemented |
| Apex Test | `LoanClosureServiceTest.cls` | `force-app/main/default/classes/` | Auto-closure & invocable tests | `LoanClosureService` | Implemented |
| Trigger | `PaymentTrigger.trigger` | `force-app/main/default/triggers/` | Delegates `Success` payments to service | `LoanManagementService` | Implemented |
| Trigger | `CollectionCaseTrigger.trigger` | `force-app/main/default/triggers/` | Auto-assigns telecallers before insert | `TelecallerAssignmentService` | Implemented |
| LWC | `customerLoanDetails` (html, js, css, meta.xml) | `force-app/main/default/lwc/customerLoanDetails/` | Single-screen telecaller workspace | `LoanManagementController` | Implemented (Add to Record Page in App Builder) |
| Flow | `Case_Escalation_Slack_Alert.flow-meta.xml` | `force-app/main/default/flows/` | Escalation alert to `#collection-manager-alerts` | `SlackNotificationService` | Draft XML (Activate in Org) |
| Flow | `Daily_Collection_Summary_Slack.flow-meta.xml` | `force-app/main/default/flows/` | 6 PM daily summary to `#daily-collection-summary` | `DailyCollectionSummaryInvocable` | Draft XML (Activate in Org) |
| Flow | `Payment_Processing_Auto_Update.flow-meta.xml` | `force-app/main/default/flows/` | Post-payment closure eligibility check | `LoanClosureService` | Draft XML (Activate in Org) |
| Flow | `Loan_Auto_Closure.flow-meta.xml` | `force-app/main/default/flows/` | Zero-balance loan & case auto-closure | `LoanClosureService` | Draft XML (Activate in Org) |
| Flow | `Field_Visit_Tracking_Notification.flow-meta.xml` | `force-app/main/default/flows/` | Field visit GPS alert to `#field-executive-updates` | `SlackNotificationService` | Draft XML (Activate in Org) |
| Security | `Collections_Manager_Access`, `Telecaller_Access`, `Field_Executive_Access` | `force-app/main/default/permissionsets/` | Role-aligned object & Apex access | Custom Objects & Classes | Implemented |
| UI/Meta | 5 Custom Tabs, Custom Labels, Customer Layout | `force-app/main/default/tabs/`, `labels/`, `layouts/` | Navigation tabs, Slack channel labels, layout | Custom Objects | Implemented |
| Integration | `Slack_Collections_Webhook.namedCredential-meta.xml` | `force-app/main/default/namedCredentials/` | Placeholder Named Credential (no secrets) | Slack App | Manual Org Setup Required |
| Scripts | `seedSampleData.apex`, `collections_audit.soql` | `scripts/` | Scratch org seeding & SOQL audit query | Custom Objects | Implemented |
| Docs | `README.md`, `docs/*.md` (8 guides) | `/`, `docs/` | Complete architecture & deployment docs | None | Implemented |

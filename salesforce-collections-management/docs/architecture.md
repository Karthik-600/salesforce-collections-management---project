# System Architecture

## 1. Architectural Overview

The **Salesforce CRM – Collections Management System** uses a layered Salesforce Enterprise Architecture pattern designed for multi-branch NPA loan recovery operations at **Srinidhi Associates**:

1. **Presentation Layer (LWC + Mobile)**:
   - `customerLoanDetails` LWC embedded on the `Customer__c` Lightning Record Page gives telecallers a unified 360-degree view (Customer, Loans, Collection Cases, Risk Indicator) with zero tab switching.
   - Salesforce Mobile App enables Field Executives to capture GPS coordinates and attach geo-tagged visit photographs via standard Salesforce Files (`ContentDocumentLink`).

2. **Service & Domain Layer (Apex)**:
   - Thin triggers (`PaymentTrigger`, `CollectionCaseTrigger`) delegate strictly to bulk-safe Apex service classes.
   - `LoanManagementService` and `LoanClosureService` maintain transactional integrity across `Payment__c`, `Loan_Account__c`, and `Collection_Case__c`.
   - `TelecallerAssignmentService` enforces workload balancing (`LEAST_LOADED` or `ROUND_ROBIN`) across active users only.
   - `RiskAnalysisService` cleanly separates deterministic rule-based scoring from optional Salesforce Einstein Prompt Builder invocation.

3. **Automation Layer (Salesforce Flows)**:
   - Record-Triggered Flows handle real-time Slack alerts for Case Escalations and Field Visits, plus automated loan closure checks.
   - A Scheduled Flow executes daily at 6:00 PM to aggregate portfolio counts via `DailyCollectionSummaryInvocable` and post to `#daily-collection-summary`.

4. **Integration & Security Layer**:
   - All outbound Slack HTTP callouts authenticate through a Salesforce **Named Credential** (`callout:Slack_Collections_Webhook`) inside a `Queueable` job implementing `Database.AllowsCallouts`.
   - Sharing is enforced via `with sharing`, `WITH SECURITY_ENFORCED`, `Schema.sObjectType` CRUD checks, and `Security.stripInaccessible`.

## 2. Licensing & Role Hierarchy Alignment

Based on the Srinidhi Associates licensing model (19 total users):
- **CEO (1 - Salesforce License)**: Full reports and executive dashboards.
- **VP (1 - Salesforce License)**: Read/Edit oversight across all custom objects.
- **Managers / Admin (2 - Salesforce License)**: `Collections_Manager_Access` permission set for case monitoring, escalations, and user control.
- **Telecallers (5 - Salesforce Platform License)**: `Telecaller_Access` permission set for customer calling and case updates.
- **Field Executives (10 - Salesforce Platform License)**: `Field_Executive_Access` permission set for field visits, GPS uploads, and payment logging.

> Note: Salesforce Platform licenses support full Apex, LWC, Flows, and API integrations, but do not include Service Cloud Omni-Channel or full CTI. Upgrading to Service Cloud is recommended for future large-scale call center expansion.

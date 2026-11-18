# Apex Implementation Guide

All Apex classes follow Salesforce Enterprise Patterns: `with sharing`, bulk-safe collections (zero SOQL/DML inside loops), CRUD/FLS checks (`Schema.sObjectType`, `WITH SECURITY_ENFORCED`, `Security.stripInaccessible`), and explicit exception handling.

## Class Inventory

1. **`LoanManagementController`**
   - `@AuraEnabled(cacheable=true) getCustomerLoanDashboard(Id customerId)`: Single round-trip DTO returning `CustomerSummary`, `List<LoanSummary>`, `List<CollectionCaseSummary>`, and `RiskAnalysisService.RiskAssessmentResult`.
   - `@AuraEnabled refreshLoanRiskAnalysis(Id loanAccountId)`: Re-evaluates and persists `Risk_Level__c` on demand.

2. **`LoanManagementService`**
   - `processSuccessfulPayments(List<Payment__c> payments)`: Aggregates successful payments per loan using a `Map<Id, Decimal>`, locks parent `Loan_Account__c` records with `FOR UPDATE`, validates against overpayments, updates `Amount_Paid__c` and `Outstanding_Amount__c`, and delegates zero-balance loans to `LoanClosureService`.
   - `recalculateLoanBalances(Set<Id> loanIds)`: Reconciles exact totals using `AggregateResult` (`SUM(Payment_Amount__c)`).

3. **`TelecallerAssignmentService`**
   - `assignTelecallers(List<Collection_Case__c> cases)`: Supports configurable `LEAST_LOADED` (default) and `ROUND_ROBIN` strategies.
   - Queries active users with the `Telecaller_Access` permission set (`Assignee.IsActive = true`), preventing assignment to inactive users.

4. **`RiskAnalysisService`**
   - `analyzeLoanRisk(Loan_Account__c, Customer__c, Collection_Case__c)`: Deterministic rule-based fallback scoring overdue days, collection efficiency, non-contactability, and escalation status to produce `LOW`, `MEDIUM`, or `HIGH` risk with all 7 required outputs.
   - `evaluateAndPersistRisk(Id loanAccountId)`: Updates `Loan_Account__c.Risk_Level__c` with FLS enforcement.
   - `buildEinsteinPromptInputMap(Id loanAccountId)`: Constructs the input map for Einstein Prompt Builder Flex Template `Collections_Loan_Risk_Analysis`.

5. **`SlackNotificationService`**
   - `@InvocableMethod sendNotificationsFromFlow(List<SlackNotificationRequest>)`: Enqueues `SlackDispatchQueueable` (`Database.AllowsCallouts`) to avoid uncommitted-work callout errors after DML.
   - Uses `callout:Slack_Collections_Webhook` Named Credential.

6. **`LoanClosureService`**
   - `@InvocableMethod closeEligibleLoansInvocable(List<Id> loanIds)` and `closeEligibleLoans(Set<Id> loanAccountIds)`: Verifies `Outstanding_Amount__c <= 0`, sets `Loan_Status__c = 'Closed'` and `Risk_Level__c = 'LOW'`, and closes open associated `Collection_Case__c` records with `Collection_Status__c = 'Recovered'`.

7. **`DailyCollectionSummaryInvocable`**
   - `@InvocableMethod executeDailySummary()`: Aggregates `Collection_Case__c` counts by `Case_Status__c` and dispatches the daily summary to `#daily-collection-summary`.

## Triggers

- **`PaymentTrigger`** (`after insert, after update`): Filters records newly entering `Payment_Status__c = 'Success'` and delegates to `LoanManagementService.processSuccessfulPayments()`.
- **`CollectionCaseTrigger`** (`before insert`): Delegates to `TelecallerAssignmentService.assignTelecallers()` so assignments occur in-memory without extra DML.

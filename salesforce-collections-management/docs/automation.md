# Salesforce Flow Automation Guide

All 5 business automation workflows are provided as Salesforce Flow Metadata XML files in `force-app/main/default/flows/` with `<status>Draft</status>` so administrators can review and activate them safely after configuring the Slack Named Credential.

## Flow Inventory

| Flow API Name | Type | Trigger Object & Criteria | Apex Action Invoked |
| :--- | :--- | :--- | :--- |
| `Case_Escalation_Slack_Alert` | Record-Triggered (After Save) | `Collection_Case__c` when `Case_Status__c` becomes `Escalated` | `SlackNotificationService` (`#collection-manager-alerts`) |
| `Daily_Collection_Summary_Slack` | Scheduled (Daily 18:00) | Runs daily at 6:00 PM | `DailyCollectionSummaryInvocable` (`#daily-collection-summary`) |
| `Payment_Processing_Auto_Update` | Record-Triggered (After Save) | `Payment__c` when `Payment_Status__c` becomes `Success` | `LoanClosureService` (after `PaymentTrigger` updates balances) |
| `Loan_Auto_Closure` | Record-Triggered (After Save) | `Loan_Account__c` when `Outstanding_Amount__c <= 0` and `Loan_Status__c != Closed` | `LoanClosureService` |
| `Field_Visit_Tracking_Notification` | Record-Triggered (After Save) | `Field_Visit__c` on Create & Update | `SlackNotificationService` (`#field-executive-updates`) |

## Manual Flow Builder Configuration & Activation Steps

1. Go to **Setup → Process Automation → Flows**.
2. Open each of the 5 deployed Flows (`Draft` status):
   - Verify the **Start** trigger criteria and schedule timezone (`Daily_Collection_Summary_Slack` is set to `18:00:00.000Z`; adjust for IST `18:00` in your org's Default Workflow User timezone).
   - Confirm the Apex Action input variables map cleanly to `$Record` fields.
3. Click **Debug** with a sample record to verify execution without errors.
4. Click **Activate** on each Flow.

### Field Visit Photo Attachment Support
- Standard Salesforce **Files** related list is enabled on `Field_Visit__c`.
- Field Executives using the Salesforce Mobile App can upload geo-tagged site photos directly to the `Field_Visit__c` record; Salesforce stores them as `ContentVersion` linked via `ContentDocumentLink`.

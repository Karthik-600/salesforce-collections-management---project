# Salesforce CRM – Collections Management System

> **Important Notice**: This repository is a **reconstructed Salesforce DX reference implementation** based on the *Salesforce CRM – Collections Management* project presentation for **Srinidhi Associates**. These files are freshly authored reference code and metadata—not previously deployed production source code. Features requiring manual Salesforce org configuration (such as Slack Named Credential endpoints, Einstein Prompt Builder activation, Flow activation, and Management Dashboards) are explicitly documented.

## 1. Business Problem

**Srinidhi Associates** is a loan recovery agency managing Non-Performing Asset (NPA) accounts for Banks and NBFCs across multiple branches and states. Prior to Salesforce adoption, operations relied on fragmented Excel spreadsheets, creating key bottlenecks:

- Manual case allocation across telecallers and field executives.
- No centralized customer, loan, and follow-up visibility.
- Delayed managerial reporting and no real-time escalation alerts.
- Limited field accountability for non-contactable borrowers.
- Baseline operational metrics: **20% Recovery Rate**, **40% Contactability**, **35% Follow-up Compliance**.

## 2. Proposed Solution

A unified **Salesforce CRM – Collections Management System** built on Salesforce Platform that centralizes customer and loan data, automates telecaller assignment and loan closure, provides a single-screen Lightning Web Component (`customerLoanDetails`), pushes real-time Slack alerts, and integrates AI-assisted risk analysis.

Target outcomes from the project presentation:
- Recovery Rate: `20% → 50%`
- Contactability: `40% → 90%`
- Follow-Up Compliance: `35% → 95%`
- ~70% reduction in manual monitoring effort.

## 3. Key Features

| Module | Implementation Status | Details |
| :--- | :--- | :--- |
| **Custom Data Model (5 Objects)** | Implemented (Metadata XML) | `Customer__c`, `Loan_Account__c`, `Collection_Case__c`, `Payment__c`, `Field_Visit__c` with relationships, formulas, and validation rules |
| **Apex Service Layer & Triggers** | Implemented (Apex + Tests) | `LoanManagementController`, `LoanManagementService`, `TelecallerAssignmentService`, `RiskAnalysisService`, `SlackNotificationService`, `LoanClosureService` |
| **Single-Screen Telecaller LWC** | Implemented (LWC Bundle) | `customerLoanDetails` — Customer, Loan, Collection Case, and Risk Indicator on one screen |
| **Flow Automation (5 Flows)** | Implemented (Draft XML) | Case Escalation, 6 PM Daily Summary, Payment Processing, Loan Auto Closure, Field Visit Tracking (require activation in org) |
| **Slack Integration** | Implemented (Apex + Named Credential template) | Channels: `#collection-manager-alerts`, `#daily-collection-summary`, `#field-executive-updates` (requires live Slack webhook in Named Credential) |
| **Einstein AI Risk Analysis** | Hybrid (Rule-Based Fallback + Prompt Builder Design) | Deterministic fallback works out of the box; Einstein Prompt Builder requires Einstein Generative AI license & manual setup |
| **Role-Based Security** | Implemented (Permission Sets) | `Collections_Manager_Access`, `Telecaller_Access`, `Field_Executive_Access` |

## 4. Technology Stack

- **Backend**: Salesforce Apex (API v61.0), SOQL, Triggers, Invocable Actions, Queueable Callouts
- **Frontend**: Lightning Web Components (LWC), HTML, CSS, JavaScript, SLDS
- **Automation**: Salesforce Record-Triggered Flows & Scheduled Flows
- **Integration**: Slack Incoming Webhooks / REST API via Salesforce Named Credentials
- **AI**: Salesforce Einstein Prompt Builder design + Deterministic Apex Rule-Based Fallback
- **Tooling**: Salesforce DX (`sf` CLI), Metadata API v61.0

## 5. System Architecture

```text
[Telecallers / Field Executives / Managers]
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
[customerLoanDetails LWC]   [Salesforce Mobile App]
        │                       │ (Field Visits + GPS + Files)
        ▼                       ▼
┌───────────────────────────────────────────────────┐
│                Salesforce Platform                │
│  Apex Controllers & Bulk-Safe Service Layer       │
│  ├── LoanManagementController                     │
│  ├── LoanManagementService + LoanClosureService   │
│  ├── TelecallerAssignmentService                  │
│  ├── RiskAnalysisService (Fallback + Einstein)    │
│  └── SlackNotificationService (Queueable)         │
│                                                   │
│  Declarative Automation (5 Flows)                 │
│  Data Model: Customer -> Loan -> Case/Payment/FV  │
└───────────────┬───────────────────┬───────────────┘
                │                   │
                ▼                   ▼
     [Named Credential]    [Einstein Prompt Builder]
                │           (Manual Org Setup Req.)
                ▼
      [Slack Workspace]
      ├── #collection-manager-alerts
      ├── #daily-collection-summary
      └── #field-executive-updates
```

## 6. Project Folder Structure

```text
salesforce-collections-management/
├── README.md
├── FILE_MANIFEST.md
├── .gitignore
├── sfdx-project.json
├── force-app/main/default/
│   ├── classes/          (7 Apex classes + 6 Test classes + 1 Callout Mock)
│   ├── triggers/         (PaymentTrigger, CollectionCaseTrigger)
│   ├── lwc/              (customerLoanDetails)
│   ├── objects/          (5 Custom Objects with fields & validation rules)
│   ├── flows/            (5 Flow metadata XML files)
│   ├── layouts/          (Customer__c page layout)
│   ├── permissionsets/   (Manager, Telecaller, Field Executive)
│   ├── tabs/             (5 Custom Object tabs)
│   ├── labels/           (Slack channel Custom Labels)
│   └── namedCredentials/ (Slack_Collections_Webhook template)
├── docs/                 (8 detailed technical architecture guides)
├── scripts/              (Anonymous Apex seed script & SOQL audit query)
└── screenshots/          (Portfolio screenshot guide)
```

## 7. Quick Start: Installation & Deployment

### Prerequisites
- [Salesforce CLI (`sf`)](https://developer.salesforce.com/tools/salesforcecli) v2+
- A Salesforce Developer Edition org, Sandbox, or Dev Hub Scratch Org

### Deploy to Target Org
```bash
# 1. Authenticate with your target org
sf org login web --alias collections-dev

# 2. Deploy all metadata
sf project deploy start --source-dir force-app --target-org collections-dev

# 3. Assign Permission Sets
sf org assign permset --name Collections_Manager_Access --target-org collections-dev

# 4. Run all Apex unit tests
sf apex run test --test-level RunLocalTests --result-format human --code-coverage --target-org collections-dev

# 5. (Optional) Seed sample Srinidhi Associates data
sf apex run --file scripts/apex/seedSampleData.apex --target-org collections-dev
```

## 8. Post-Deployment Manual Configuration

1. **Slack Named Credential**: Update `Slack_Collections_Webhook` in Setup → Named Credentials with your real Slack Incoming Webhook URL.
2. **Activate Flows**: Open Flow Builder and activate the 5 deployed Flows after verifying the Slack Named Credential.
3. **Add LWC to Record Page**: Edit the `Customer__c` Lightning Record Page in Lightning App Builder and drag `Customer Loan & Collection Details` onto the main region.
4. **Einstein Prompt Builder**: Follow [`docs/einstein-ai-configuration.md`](docs/einstein-ai-configuration.md) to configure the `Collections_Loan_Risk_Analysis` Flex Prompt Template in Einstein-licensed orgs.
5. **Reports & Dashboards**: Build the Loan Dashboard, Call Records, and Payment Dashboards in Reports & Dashboards using the deployed custom objects.

## 9. Documentation Index

- [System Architecture](docs/architecture.md)
- [Data Model & Relationships](docs/data-model.md)
- [Apex Implementation](docs/apex-implementation.md)
- [LWC Implementation](docs/lwc-implementation.md)
- [Flow Automation](docs/automation.md)
- [Slack Integration](docs/slack-integration.md)
- [Einstein AI Configuration](docs/einstein-ai-configuration.md)
- [Deployment & GitHub Guide](docs/deployment-guide.md)
- [Complete File Manifest](FILE_MANIFEST.md)

## 10. Future Enhancements (Roadmap from Presentation)

- **Collect Payment Quick Action** directly inside the `customerLoanDetails` LWC.
- **Settlement Creation Workflow** with automatic waiver calculation and Bank approval routing.
- **CTI / Dialer Integration** with auto-logged call duration and recordings.
- **Promise-to-Pay (PTP) Tracking** with automated customer reminders and escalation on broken promises.
- **WhatsApp / SMS Notifications** and an **External Bank Monitoring Portal** (Experience Cloud).

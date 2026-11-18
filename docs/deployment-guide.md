# Deployment & GitHub Upload Guide

## 1. Prerequisites

- Salesforce CLI (`sf`) installed (`npm install -g @salesforce/cli`)
- Git installed
- Target Salesforce Developer Edition Org, Sandbox, or Dev Hub enabled for Scratch Orgs

## 2. Deploying to Salesforce

```bash
# Authenticate target org
sf org login web --alias collections-org

# Validate deployment first (check-only)
sf project deploy start --source-dir force-app --dry-run --test-level RunLocalTests --target-org collections-org

# Deploy metadata to org
sf project deploy start --source-dir force-app --target-org collections-org

# Assign Manager Permission Set to your admin user
sf org assign permset --name Collections_Manager_Access --target-org collections-org

# Run all unit tests with code coverage report
sf apex run test --test-level RunLocalTests --result-format human --code-coverage --target-org collections-org
```

## 3. Post-Deployment Manual Checklist

- [ ] Update `Slack_Collections_Webhook` Named Credential with your workspace webhook URL / Bot Token.
- [ ] Activate all 5 Flows in **Setup → Flows** (`Case_Escalation_Slack_Alert`, `Daily_Collection_Summary_Slack`, `Payment_Processing_Auto_Update`, `Loan_Auto_Closure`, `Field_Visit_Tracking_Notification`).
- [ ] Add `customerLoanDetails` LWC to the `Customer__c` Lightning Record Page via Lightning App Builder.
- [ ] Assign `Telecaller_Access` and `Field_Executive_Access` permission sets to respective users.
- [ ] Configure Einstein Prompt Builder (`Collections_Loan_Risk_Analysis`) if your org has Einstein Generative AI licenses.
- [ ] Create Management Reports & Dashboards (Loan Dashboard, Call Records, Payment Dashboards).

## 4. Uploading to GitHub

```bash
cd salesforce-collections-management
git init
git add .
git commit -m "feat: initial Salesforce DX Collections Management reference implementation"
git branch -M main
git remote add origin https://github.com/<your-username>/salesforce-collections-management.git
git push -u origin main
```

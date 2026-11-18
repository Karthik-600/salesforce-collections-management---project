# Lightning Web Component Implementation (`customerLoanDetails`)

## Business Objective

Before `customerLoanDetails`, telecallers had to open three separate tabs (Customer → Loan Account → Collection Case) before placing a single recovery call. This LWC consolidates all four operational sections directly onto the `Customer__c` Lightning Record Page:

1. **Section 1 — Customer Details**: Name, Phone Number (`lightning-formatted-phone`), Email (`lightning-formatted-email`), Branch/State, Address, and Contactability Status.
2. **Section 2 — Loan Details**: Loan Number, Total Loan Amount (INR), Outstanding Amount (emphasized), Amount Paid, and Loan Status for each linked `Loan_Account__c`.
3. **Section 3 — Collection Case**: Case Number, Case Status, Priority, Assigned Telecaller, and Next Follow-Up Date for each linked `Collection_Case__c`.
4. **Section 4 — Risk Indicator & Recovery Guidance**: Risk Classification (`LOW` / `MEDIUM` / `HIGH`), Collection Efficiency %, Field Visit Required (`YES`/`NO`), Suggested Communication Tone, 3-Line Professional Assessment, and Recommended Telecaller Action, along with transparent attribution of the analysis source (`Rule-Based Fallback` vs. `Einstein Prompt Builder`).

## Component Files

- `force-app/main/default/lwc/customerLoanDetails/customerLoanDetails.html`
- `force-app/main/default/lwc/customerLoanDetails/customerLoanDetails.js`
- `force-app/main/default/lwc/customerLoanDetails/customerLoanDetails.css`
- `force-app/main/default/lwc/customerLoanDetails/customerLoanDetails.js-meta.xml`

## Apex Wiring

```javascript
import getCustomerLoanDashboard from '@salesforce/apex/LoanManagementController.getCustomerLoanDashboard';
```

Uses `@wire(getCustomerLoanDashboard, { customerId: '$recordId' })` with `refreshApex` wired to the card's Refresh button. Handles loading (`lightning-spinner`), error (`slds-alert_error`), and empty child-record states cleanly.

## Manual Lightning App Builder Configuration

1. Navigate to **Setup → Object Manager → Customer (`Customer__c`) → Lightning Record Pages**.
2. Create or edit the default Customer Record Page.
3. Under **Custom Components**, drag **Customer Loan & Collection Details** (`customerLoanDetails`) into the main column.
4. Click **Save** and **Activate** (assign as Org Default or App Default for Collections App).

# Data Model & Relationships

## Entity Relationship Overview

```text
Customer__c (Master)
  ├──< Loan_Account__c (Master-Detail: Customer__c)
  │      ├──< Payment__c (Master-Detail: Loan_Account__c, Lookup: Customer__c)
  │      ├──< Collection_Case__c (Lookup: Loan_Account__c, Lookup: Customer__c)
  │      └──< Field_Visit__c (Lookup: Loan_Account__c, Lookup: Customer__c)
  │
  User (Standard)
  ├──< Collection_Case__c (Lookup: Assigned_Telecaller__c, Assigned_Field_Executive__c)
  └──< Field_Visit__c (Lookup: Assigned_Executive__c)
```

## 1. Customer__c (`Customer`)
- **Name Field**: `Name` (Text — Customer Name)
- **Sharing Model**: `ReadWrite`
- **Fields**:
  - `Phone_Number__c` (Phone, Required, Track History)
  - `Email__c` (Email)
  - `Address__c` (LongTextArea 1000)
  - `State__c` (Picklist: Tamil Nadu, Karnataka, Maharashtra, Telangana, Andhra Pradesh, Kerala, Delhi, Gujarat, Other)
  - `Branch__c` (Text 100)
  - `Contactability_Status__c` (Picklist: Contactable, Non-Contactable, Switched Off, Wrong Number, Pending Verification)
- **Validation Rule**: `Require_Valid_Phone_Length` — requires at least 10 characters.

## 2. Loan_Account__c (`Loan Account`)
- **Name Field**: `Name` (AutoNumber: `LN-{0000}`, Label: Loan Number)
- **Sharing Model**: `ControlledByParent` (Master-Detail to `Customer__c`)
- **Fields**:
  - `Customer__c` (Master-Detail → `Customer__c`)
  - `Loan_Amount__c` (Currency 16,2, Required)
  - `Outstanding_Amount__c` (Currency 16,2, Required, Track History)
  - `Amount_Paid__c` (Currency 16,2, Default 0, Track History)
  - `Interest_Rate__c` (Percent 5,2)
  - `Due_Date__c` (Date, Required)
  - `Loan_Status__c` (Picklist: Active, Overdue, NPA, Settled, Closed)
  - `Risk_Level__c` (Picklist: LOW, MEDIUM, HIGH)
  - `Collection_Efficiency__c` (Formula Percent: `IF(Loan_Amount__c > 0, Amount_Paid__c / Loan_Amount__c, 0)`)
  - `Days_Overdue__c` (Formula Number: days past `Due_Date__c` when not Closed)
- **Validation Rule**: `Non_Negative_Balances` — prevents zero/negative loan amounts or negative balances.

## 3. Collection_Case__c (`Collection Case`)
- **Name Field**: `Name` (AutoNumber: `CC-{00000}`, Label: Case Number)
- **Sharing Model**: `Private`
- **Fields**:
  - `Customer__c` (Lookup → `Customer__c`, Required)
  - `Loan_Account__c` (Lookup → `Loan_Account__c`, Required)
  - `Assigned_Telecaller__c` (Lookup → `User`)
  - `Assigned_Field_Executive__c` (Lookup → `User`)
  - `Case_Status__c` (Picklist: New, In Progress, Follow-Up Scheduled, Field Visit Requested, Escalated, Closed)
  - `Priority__c` (Picklist: Low, Medium, High, Critical)
  - `Escalation_Reason__c` (LongTextArea 1000)
  - `Next_Follow_Up_Date__c` (Date)
  - `Collection_Status__c` (Picklist: Pending, Partial Payment, Promise to Pay, Non-Contactable, Recovered, Settled)
- **Validation Rule**: `Require_Escalation_Reason` — `Escalation_Reason__c` is mandatory when `Case_Status__c = 'Escalated'`.

## 4. Payment__c (`Payment`)
- **Name Field**: `Name` (AutoNumber: `PAY-{00000}`, Label: Payment Reference)
- **Sharing Model**: `ControlledByParent` (Master-Detail to `Loan_Account__c`)
- **Fields**:
  - `Loan_Account__c` (Master-Detail → `Loan_Account__c`)
  - `Customer__c` (Lookup → `Customer__c`, Required)
  - `Payment_Amount__c` (Currency 16,2, Required)
  - `Payment_Date__c` (Date, Required, Default `TODAY()`)
  - `Payment_Mode__c` (Picklist: Cash, UPI, NEFT/RTGS, Cheque, Bank Transfer, Card)
  - `Payment_Status__c` (Picklist: Pending, Success, Failed, Reversed)
- **Validation Rule**: `Positive_Payment_Amount` — requires `Payment_Amount__c > 0`.

## 5. Field_Visit__c (`Field Visit`)
- **Name Field**: `Name` (AutoNumber: `FV-{00000}`, Label: Visit Reference)
- **Sharing Model**: `Private`
- **Fields**:
  - `Customer__c` (Lookup → `Customer__c`, Required)
  - `Loan_Account__c` (Lookup → `Loan_Account__c`, Required)
  - `Assigned_Executive__c` (Lookup → `User`)
  - `Visit_Date__c` (DateTime, Required)
  - `GPS_Latitude__c` (Number 9,6)
  - `GPS_Longitude__c` (Number 9,6)
  - `Visit_Status__c` (Picklist: Scheduled, Completed, Customer Unavailable, Address Not Found, Cancelled)
  - `Visit_Notes__c` (LongTextArea 2000)
- **Validation Rule**: `Valid_GPS_Coordinates` — enforces Latitude `[-90, 90]` and Longitude `[-180, 180]`.
- **Visit Photographs**: Stored natively using Salesforce Files (`ContentVersion` / `ContentDocumentLink`) linked to `Field_Visit__c.Id`.

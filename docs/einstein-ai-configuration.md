# Einstein AI & Risk Analysis Configuration

## Architectural Transparency: Rule-Based Fallback vs. Einstein Prompt Builder

This repository strictly separates deterministic Apex logic from Salesforce Einstein Generative AI:

1. **Rule-Based Fallback Risk Engine (`RiskAnalysisService.calculateRuleBasedRisk`)**:
   - Implemented in pure Apex and works immediately in Developer Edition orgs and Scratch Orgs without paid AI add-ons.
   - Scores overdue days, collection efficiency %, non-contactability, and case escalation to produce `LOW`, `MEDIUM`, or `HIGH` risk and all 7 required analytical outputs.
   - Explicitly tags `analysisSource = 'Rule-Based Fallback'` in the UI and DTO.
2. **Salesforce Einstein Prompt Builder Integration**:
   - Requires a Salesforce org licensed for **Einstein 1 / Einstein Generative AI** with **Prompt Builder** enabled.
   - `RiskAnalysisService.buildEinsteinPromptInputMap(loanAccountId)` prepares the exact `Input:Loan_Account` parameter map expected by `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Collections_Loan_Risk_Analysis', ...)`.

## Required Output Structure (7 Fields)

1. **Loan Metrics Summary**
2. **Collection Efficiency %**
3. **Risk Level Indicator** (`LOW`, `MEDIUM`, `HIGH`)
4. **3-Line Professional Assessment**
5. **Recommended Telecaller Action**
6. **Suggested Communication Tone**
7. **Field Visit Required** (`YES` / `NO`)

## Manual Salesforce Setup to Activate Einstein Prompt Builder

1. **Enable Einstein Generative AI**:
   - Go to **Setup → Einstein Setup** and toggle **Turn on Einstein** to **On**.
2. **Assign Required Permissions**:
   - Assign **Prompt Template Manager** (to Admins/Architects) and **Prompt Template User** (to Telecallers and Managers).
3. **Create the Flex Prompt Template**:
   - Go to **Setup → Einstein Studio → Prompt Builder → New Prompt Template**.
   - **Template Type**: `Flex`
   - **Template Name**: `Collections Loan Risk Analysis`
   - **API Name**: `Collections_Loan_Risk_Analysis`
   - **Sources**: Add `Loan_Account__c` (API Input Name: `Loan_Account`).
4. **Prompt Template Instructions**:
   ```text
   You are a senior NPA loan recovery analyst for Srinidhi Associates.
   Analyze Loan Account {!$Input:Loan_Account.Name}:
   - Loan Amount: {!$Input:Loan_Account.Loan_Amount__c}
   - Amount Paid: {!$Input:Loan_Account.Amount_Paid__c}
   - Outstanding Amount: {!$Input:Loan_Account.Outstanding_Amount__c}
   - Days Overdue: {!$Input:Loan_Account.Days_Overdue__c}
   - Loan Status: {!$Input:Loan_Account.Loan_Status__c}
   - Customer Contactability: {!$Input:Loan_Account.Customer__r.Contactability_Status__c}

   Return structured JSON containing:
   loanMetricsSummary, collectionEfficiencyPercent, riskLevel (LOW|MEDIUM|HIGH),
   threeLineAssessment, recommendedTelecallerAction, suggestedCommunicationTone,
   and fieldVisitRequired (YES|NO).
   ```
5. **Save & Activate** the Prompt Template, then invoke it from `RiskAnalysisService` using `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()`.

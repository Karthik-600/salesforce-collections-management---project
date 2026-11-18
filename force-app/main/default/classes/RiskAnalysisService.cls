/**
 * @description       : Provides loan recovery risk classification (LOW, MEDIUM, HIGH)
 *                      and structured recovery recommendations.
 *
 *                      IMPORTANT ARCHITECTURAL SEPARATION:
 *                      1. Rule-Based Fallback Engine (implemented in Apex below):
 *                         Deterministic scoring based on overdue days, collection efficiency,
 *                         outstanding balance, and customer contactability. Works in every org.
 *                      2. Salesforce Einstein Prompt Builder Integration (configuration-dependent):
 *                         Designed to invoke the Flex Prompt Template 'Collections_Loan_Risk_Analysis'
 *                         via ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate().
 *                         Requires Einstein Generative AI licensing and manual Prompt Builder setup.
 *                         See docs/einstein-ai-configuration.md for activation steps.
 * @group             : Collections Management
 */
public with sharing class RiskAnalysisService {

    public static final String PROMPT_TEMPLATE_API_NAME = 'Collections_Loan_Risk_Analysis';

    public class RiskAssessmentResult {
        @AuraEnabled public Id loanAccountId { get; set; }
        @AuraEnabled public String loanNumber { get; set; }
        @AuraEnabled public String loanMetricsSummary { get; set; }
        @AuraEnabled public Decimal collectionEfficiencyPercent { get; set; }
        @AuraEnabled public String riskLevel { get; set; } // LOW, MEDIUM, HIGH
        @AuraEnabled public String threeLineAssessment { get; set; }
        @AuraEnabled public String recommendedTelecallerAction { get; set; }
        @AuraEnabled public String suggestedCommunicationTone { get; set; }
        @AuraEnabled public String fieldVisitRequired { get; set; } // YES or NO
        @AuraEnabled public String analysisSource { get; set; } // 'Rule-Based Fallback' or 'Einstein Prompt Builder'
    }

    /**
     * @description Evaluates loan risk in memory using the deterministic rule-based engine.
     *              Used by LWC controllers when Einstein Prompt Builder is not enabled in the org.
     * @param loan Loan_Account__c record
     * @param customer Optional Customer__c record for contactability context
     * @param activeCase Optional Collection_Case__c record for escalation context
     * @return RiskAssessmentResult
     */
    public static RiskAssessmentResult analyzeLoanRisk(
        Loan_Account__c loan,
        Customer__c customer,
        Collection_Case__c activeCase
    ) {
        if (loan == null) {
            throw new IllegalArgumentException('Loan Account record cannot be null.');
        }

        // Delegate to deterministic rule-based engine.
        // To enable Einstein Prompt Builder in licensed orgs, wire invokeEinsteinPromptTemplate()
        // as documented in docs/einstein-ai-configuration.md.
        return calculateRuleBasedRisk(loan, customer, activeCase);
    }

    /**
     * @description Bulk-safe risk evaluation and persistence of Risk_Level__c on Loan_Account__c.
     * @param loanAccountId Single Loan_Account__c Id
     * @return RiskAssessmentResult
     */
    public static RiskAssessmentResult evaluateAndPersistRisk(Id loanAccountId) {
        if (loanAccountId == null) {
            throw new IllegalArgumentException('Loan Account ID cannot be null.');
        }

        List<Loan_Account__c> loans = [
            SELECT Id, Name, Customer__c, Loan_Amount__c, Outstanding_Amount__c,
                   Amount_Paid__c, Interest_Rate__c, Due_Date__c, Loan_Status__c,
                   Risk_Level__c, Collection_Efficiency__c, Days_Overdue__c,
                   Customer__r.Contactability_Status__c, Customer__r.Branch__c, Customer__r.State__c
            FROM Loan_Account__c
            WHERE Id = :loanAccountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (loans.isEmpty()) {
            throw new IllegalArgumentException('Loan Account not found for ID: ' + loanAccountId);
        }

        Loan_Account__c loan = loans[0];
        List<Collection_Case__c> cases = [
            SELECT Id, Case_Status__c, Priority__c, Collection_Status__c, Escalation_Reason__c
            FROM Collection_Case__c
            WHERE Loan_Account__c = :loan.Id
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        Customer__c cust = new Customer__c(
            Id = loan.Customer__c,
            Contactability_Status__c = loan.Customer__r != null ? loan.Customer__r.Contactability_Status__c : null
        );

        RiskAssessmentResult result = analyzeLoanRisk(loan, cust, cases.isEmpty() ? null : cases[0]);

        if (Schema.sObjectType.Loan_Account__c.isUpdateable() && loan.Risk_Level__c != result.riskLevel) {
            loan.Risk_Level__c = result.riskLevel;
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<Loan_Account__c>{ loan }
            );
            update decision.getRecords();
        }

        return result;
    }

    /**
     * @description Deterministic rule-based fallback risk engine.
     *              Explicitly labeled as 'Rule-Based Fallback' so users never confuse it with
     *              Salesforce Einstein Generative AI.
     */
    @TestVisible
    private static RiskAssessmentResult calculateRuleBasedRisk(
        Loan_Account__c loan,
        Customer__c customer,
        Collection_Case__c activeCase
    ) {
        Decimal loanAmt = loan.Loan_Amount__c != null ? loan.Loan_Amount__c : 0;
        Decimal paidAmt = loan.Amount_Paid__c != null ? loan.Amount_Paid__c : 0;
        Decimal outstandingAmt = loan.Outstanding_Amount__c != null ? loan.Outstanding_Amount__c : 0;

        Decimal efficiencyPct = 0;
        if (loanAmt > 0) {
            efficiencyPct = ((paidAmt / loanAmt) * 100).setScale(2, System.RoundingMode.HALF_UP);
        }

        Integer daysOverdue = 0;
        if (loan.Due_Date__c != null && loan.Loan_Status__c != 'Closed' && loan.Due_Date__c < Date.today()) {
            daysOverdue = loan.Due_Date__c.daysBetween(Date.today());
        }

        Boolean isNonContactable = customer != null &&
            (customer.Contactability_Status__c == 'Non-Contactable' ||
             customer.Contactability_Status__c == 'Wrong Number' ||
             customer.Contactability_Status__c == 'Switched Off');

        Boolean isEscalated = activeCase != null && activeCase.Case_Status__c == 'Escalated';

        // Scoring heuristic (0 - 100)
        Integer riskScore = 0;
        if (loan.Loan_Status__c == 'Closed' || outstandingAmt <= 0) {
            riskScore = 0;
        } else {
            if (daysOverdue >= 90 || loan.Loan_Status__c == 'NPA') {
                riskScore += 45;
            } else if (daysOverdue >= 30) {
                riskScore += 25;
            } else if (daysOverdue > 0) {
                riskScore += 10;
            }

            if (efficiencyPct < 25) {
                riskScore += 30;
            } else if (efficiencyPct < 60) {
                riskScore += 15;
            }

            if (isNonContactable) {
                riskScore += 20;
            }

            if (isEscalated) {
                riskScore += 15;
            }
        }

        String riskLevel;
        String action;
        String tone;
        String fieldVisitRequired;
        String assessment;

        if (riskScore >= 60) {
            riskLevel = 'HIGH';
            fieldVisitRequired = 'YES';
            tone = 'Firm, Compliance-Focused & Escalation-Ready';
            action = 'Initiate immediate supervisor escalation, verify alternate contact numbers, and dispatch a Field Executive with GPS verification.';
            assessment =
                'Account ' + loan.Name + ' exhibits critical delinquency risk with ' + daysOverdue + ' days overdue and ' + efficiencyPct + '% collection efficiency.\n' +
                'Outstanding exposure stands at INR ' + outstandingAmt.format() + ' against original principal of INR ' + loanAmt.format() + '.\n' +
                'Immediate field intervention and structured settlement evaluation are strongly advised.';
        } else if (riskScore >= 30) {
            riskLevel = 'MEDIUM';
            fieldVisitRequired = isNonContactable ? 'YES' : 'NO';
            tone = 'Structured, Persuasive & Solution-Oriented';
            action = 'Conduct structured telecalling follow-up to secure a dated Promise-to-Pay (PTP) or partial installment within 72 hours.';
            assessment =
                'Account ' + loan.Name + ' shows moderate delinquency pressure (' + daysOverdue + ' days overdue) with ' + efficiencyPct + '% recovered to date.\n' +
                'Remaining balance of INR ' + outstandingAmt.format() + ' requires proactive cadence to prevent slippage into NPA.\n' +
                'Negotiating a documented partial payment plan is the highest-yield recovery step.';
        } else {
            riskLevel = 'LOW';
            fieldVisitRequired = 'NO';
            tone = 'Courteous, Consultative & Relationship-Preserving';
            action = 'Send a polite payment reminder and confirm upcoming installment date via standard telecalling cadence.';
            assessment =
                'Account ' + loan.Name + ' is performing within acceptable recovery thresholds with ' + efficiencyPct + '% collection efficiency.\n' +
                'Current outstanding balance is INR ' + outstandingAmt.format() + ' with ' + daysOverdue + ' days past due.\n' +
                'Routine reminder follow-up is sufficient; no field escalation is required at this time.';
        }

        RiskAssessmentResult result = new RiskAssessmentResult();
        result.loanAccountId = loan.Id;
        result.loanNumber = loan.Name;
        result.loanMetricsSummary =
            'Principal: INR ' + loanAmt.format() +
            ' | Paid: INR ' + paidAmt.format() +
            ' | Outstanding: INR ' + outstandingAmt.format() +
            ' | Days Overdue: ' + daysOverdue;
        result.collectionEfficiencyPercent = efficiencyPct;
        result.riskLevel = riskLevel;
        result.threeLineAssessment = assessment;
        result.recommendedTelecallerAction = action;
        result.suggestedCommunicationTone = tone;
        result.fieldVisitRequired = fieldVisitRequired;
        result.analysisSource = 'Rule-Based Fallback';

        return result;
    }

    /**
     * @description Builds the structured input map required by Salesforce Einstein Prompt Builder
     *              for Flex Prompt Template 'Collections_Loan_Risk_Analysis'.
     *              NOTE: Actual ConnectApi.EinsteinLLM execution requires Einstein Generative AI
     *              add-on licenses and manual Prompt Template activation in Setup.
     *              See docs/einstein-ai-configuration.md for complete activation instructions.
     * @param loanAccountId Id of Loan_Account__c
     * @return Map<String, Object> Input parameters formatted for Einstein Prompt Builder
     */
    public static Map<String, Object> buildEinsteinPromptInputMap(Id loanAccountId) {
        if (loanAccountId == null) {
            throw new IllegalArgumentException('Loan Account ID is required to build Einstein prompt input.');
        }

        Map<String, Object> inputParams = new Map<String, Object>();
        Map<String, String> loanRecordRef = new Map<String, String>{
            'id' => String.valueOf(loanAccountId)
        };
        inputParams.put('Input:Loan_Account', loanRecordRef);
        return inputParams;
    }
}

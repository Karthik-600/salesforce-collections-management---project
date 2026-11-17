/**
 * @description       : Unit tests for RiskAnalysisService verifying LOW, MEDIUM, and HIGH
 *                      risk classification, collection efficiency calculation, field visit
 *                      recommendations, Einstein prompt input map builder, and null handling.
 */
@isTest
private class RiskAnalysisServiceTest {

    @isTest
    static void testHighRiskClassification() {
        Customer__c cust = new Customer__c(
            Name = 'Suresh Babu',
            Phone_Number__c = '+919841011111',
            Contactability_Status__c = 'Non-Contactable'
        );
        insert cust;

        Loan_Account__c loan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 600000,
            Outstanding_Amount__c = 550000,
            Amount_Paid__c = 50000,
            Due_Date__c = Date.today().addDays(-120),
            Loan_Status__c = 'NPA'
        );
        insert loan;

        Collection_Case__c escalatedCase = new Collection_Case__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Case_Status__c = 'Escalated',
            Priority__c = 'Critical',
            Escalation_Reason__c = 'Customer unreachable for 90+ days'
        );
        insert escalatedCase;

        Test.startTest();
        RiskAnalysisService.RiskAssessmentResult result =
            RiskAnalysisService.evaluateAndPersistRisk(loan.Id);
        Test.stopTest();

        System.assertEquals('HIGH', result.riskLevel, 'NPA + Non-Contactable + Escalated must be HIGH risk');
        System.assertEquals('YES', result.fieldVisitRequired, 'High risk account should require field visit');
        System.assertEquals('Rule-Based Fallback', result.analysisSource, 'Source must clearly identify rule-based fallback');
        System.assert(result.collectionEfficiencyPercent < 10, 'Efficiency should be ~8.33%');

        Loan_Account__c updatedLoan = [SELECT Risk_Level__c FROM Loan_Account__c WHERE Id = :loan.Id];
        System.assertEquals('HIGH', updatedLoan.Risk_Level__c, 'Persisted Risk_Level__c should be HIGH');
    }

    @isTest
    static void testMediumRiskClassification() {
        Customer__c cust = new Customer__c(
            Name = 'Meena Krishnan',
            Phone_Number__c = '+919841022222',
            Contactability_Status__c = 'Contactable'
        );

        Loan_Account__c loan = new Loan_Account__c(
            Loan_Amount__c = 200000,
            Outstanding_Amount__c = 120000,
            Amount_Paid__c = 80000,
            Due_Date__c = Date.today().addDays(-45),
            Loan_Status__c = 'Overdue'
        );

        Test.startTest();
        RiskAnalysisService.RiskAssessmentResult result =
            RiskAnalysisService.analyzeLoanRisk(loan, cust, null);
        Test.stopTest();

        System.assertEquals('MEDIUM', result.riskLevel, '45 days overdue + 40% paid should be MEDIUM risk');
        System.assertEquals('NO', result.fieldVisitRequired, 'Contactable medium risk should not force field visit');
        System.assertEquals(40.00, result.collectionEfficiencyPercent, 'Collection efficiency should be 40%');
    }

    @isTest
    static void testLowRiskClassification() {
        Customer__c cust = new Customer__c(
            Name = 'Karthik Subramanian',
            Phone_Number__c = '+919841033333',
            Contactability_Status__c = 'Contactable'
        );

        Loan_Account__c loan = new Loan_Account__c(
            Loan_Amount__c = 300000,
            Outstanding_Amount__c = 50000,
            Amount_Paid__c = 250000,
            Due_Date__c = Date.today().addDays(15),
            Loan_Status__c = 'Active'
        );

        Test.startTest();
        RiskAnalysisService.RiskAssessmentResult result =
            RiskAnalysisService.analyzeLoanRisk(loan, cust, null);
        Test.stopTest();

        System.assertEquals('LOW', result.riskLevel, 'Current loan with >80% paid should be LOW risk');
        System.assertEquals('NO', result.fieldVisitRequired, 'Low risk should not require field visit');
    }

    @isTest
    static void testNullInputsAndEinsteinPromptInputMap() {
        Boolean threwOnNullLoan = false;
        try {
            RiskAnalysisService.analyzeLoanRisk(null, null, null);
        } catch (IllegalArgumentException ex) {
            threwOnNullLoan = true;
        }
        System.assertEquals(true, threwOnNullLoan, 'Null loan must throw IllegalArgumentException');

        Boolean threwOnNullId = false;
        try {
            RiskAnalysisService.buildEinsteinPromptInputMap(null);
        } catch (IllegalArgumentException ex) {
            threwOnNullId = true;
        }
        System.assertEquals(true, threwOnNullId, 'Null ID must throw IllegalArgumentException');

        Customer__c cust = new Customer__c(Name = 'Test Cust', Phone_Number__c = '+919000000001');
        insert cust;
        Loan_Account__c loan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 50000,
            Outstanding_Amount__c = 50000,
            Due_Date__c = Date.today()
        );
        insert loan;

        Map<String, Object> promptMap = RiskAnalysisService.buildEinsteinPromptInputMap(loan.Id);
        System.assertEquals(true, promptMap.containsKey('Input:Loan_Account'), 'Einstein prompt map should include Loan_Account input');
    }
}

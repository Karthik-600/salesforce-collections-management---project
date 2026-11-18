/**
 * @description       : Unit tests for LoanManagementController covering positive retrieval,
 *                      empty loan/case states, null input handling, and risk refresh.
 */
@isTest
private class LoanManagementControllerTest {

    @TestSetup
    static void setupData() {
        Customer__c cust = new Customer__c(
            Name = 'Rajesh Kumar',
            Phone_Number__c = '+919840012345',
            Email__c = 'rajesh.kumar@example.com',
            Address__c = '42 Anna Salai, Chennai',
            State__c = 'Tamil Nadu',
            Branch__c = 'Chennai Central',
            Contactability_Status__c = 'Contactable'
        );
        insert cust;

        Loan_Account__c loan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 500000,
            Outstanding_Amount__c = 350000,
            Amount_Paid__c = 150000,
            Interest_Rate__c = 12.5,
            Due_Date__c = Date.today().addDays(-45),
            Loan_Status__c = 'Overdue',
            Risk_Level__c = 'MEDIUM'
        );
        insert loan;

        Collection_Case__c cCase = new Collection_Case__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Assigned_Telecaller__c = UserInfo.getUserId(),
            Case_Status__c = 'In Progress',
            Priority__c = 'High',
            Next_Follow_Up_Date__c = Date.today().addDays(2),
            Collection_Status__c = 'Promise to Pay'
        );
        insert cCase;
    }

    @isTest
    static void testGetCustomerLoanDashboardPositive() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];

        Test.startTest();
        LoanManagementController.CustomerLoanDashboardDTO dto =
            LoanManagementController.getCustomerLoanDashboard(cust.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto, 'Dashboard DTO should not be null');
        System.assertEquals('Rajesh Kumar', dto.customer.name, 'Customer name should match');
        System.assertEquals(true, dto.hasLoans, 'Customer should have loan accounts');
        System.assertEquals(1, dto.loans.size(), 'Should return one loan account');
        System.assertEquals(true, dto.hasCases, 'Customer should have collection cases');
        System.assertEquals(1, dto.collectionCases.size(), 'Should return one collection case');
        System.assertNotEquals(null, dto.riskAssessment, 'Risk assessment should be populated');
    }

    @isTest
    static void testGetCustomerLoanDashboardEmptyChildRecords() {
        Customer__c emptyCust = new Customer__c(
            Name = 'Priya Nair',
            Phone_Number__c = '+919840099999',
            State__c = 'Kerala',
            Branch__c = 'Kochi',
            Contactability_Status__c = 'Contactable'
        );
        insert emptyCust;

        Test.startTest();
        LoanManagementController.CustomerLoanDashboardDTO dto =
            LoanManagementController.getCustomerLoanDashboard(emptyCust.Id);
        Test.stopTest();

        System.assertEquals(false, dto.hasLoans, 'hasLoans should be false when no loans exist');
        System.assertEquals(false, dto.hasCases, 'hasCases should be false when no cases exist');
        System.assertEquals(null, dto.riskAssessment, 'Risk assessment should be null without loans');
    }

    @isTest
    static void testGetCustomerLoanDashboardNullInput() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            LoanManagementController.getCustomerLoanDashboard(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Null customerId must throw AuraHandledException');
    }

    @isTest
    static void testRefreshLoanRiskAnalysisPositiveAndNull() {
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];

        Test.startTest();
        RiskAnalysisService.RiskAssessmentResult result =
            LoanManagementController.refreshLoanRiskAnalysis(loan.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Refreshed risk result should not be null');
        System.assertNotEquals(null, result.riskLevel, 'Risk level should be calculated');

        Boolean nullError = false;
        try {
            LoanManagementController.refreshLoanRiskAnalysis(null);
        } catch (AuraHandledException ex) {
            nullError = true;
        }
        System.assertEquals(true, nullError, 'Null loanAccountId must throw AuraHandledException');
    }
}

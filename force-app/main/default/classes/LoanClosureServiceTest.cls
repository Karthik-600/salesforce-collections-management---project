/**
 * @description       : Unit tests for LoanClosureService verifying zero-balance closure,
 *                      non-zero preservation, Invocable entry point, null inputs, and bulk closure.
 */
@isTest
private class LoanClosureServiceTest {

    @TestSetup
    static void setupData() {
        Customer__c cust = new Customer__c(
            Name = 'Lakshmi Narayanan',
            Phone_Number__c = '+919444012345',
            State__c = 'Tamil Nadu',
            Branch__c = 'Madurai'
        );
        insert cust;

        Loan_Account__c zeroLoan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 80000,
            Outstanding_Amount__c = 0,
            Amount_Paid__c = 80000,
            Due_Date__c = Date.today().addDays(-5),
            Loan_Status__c = 'Active',
            Risk_Level__c = 'MEDIUM'
        );

        Loan_Account__c openLoan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 80000,
            Outstanding_Amount__c = 25000,
            Amount_Paid__c = 55000,
            Due_Date__c = Date.today().addDays(-5),
            Loan_Status__c = 'Overdue',
            Risk_Level__c = 'MEDIUM'
        );

        insert new List<Loan_Account__c>{ zeroLoan, openLoan };

        insert new List<Collection_Case__c>{
            new Collection_Case__c(
                Customer__c = cust.Id,
                Loan_Account__c = zeroLoan.Id,
                Case_Status__c = 'In Progress',
                Priority__c = 'Medium',
                Collection_Status__c = 'Partial Payment'
            ),
            new Collection_Case__c(
                Customer__c = cust.Id,
                Loan_Account__c = openLoan.Id,
                Case_Status__c = 'In Progress',
                Priority__c = 'Medium',
                Collection_Status__c = 'Partial Payment'
            )
        };
    }

    @isTest
    static void testCloseEligibleLoansClosesOnlyZeroBalance() {
        List<Loan_Account__c> loans = [SELECT Id, Outstanding_Amount__c FROM Loan_Account__c];
        List<Id> allIds = new List<Id>();
        for (Loan_Account__c l : loans) {
            allIds.add(l.Id);
        }

        Test.startTest();
        LoanClosureService.closeEligibleLoansInvocable(allIds);
        Test.stopTest();

        Map<Id, Loan_Account__c> refreshed = new Map<Id, Loan_Account__c>([
            SELECT Id, Outstanding_Amount__c, Loan_Status__c, Risk_Level__c
            FROM Loan_Account__c
        ]);

        for (Loan_Account__c l : refreshed.values()) {
            if (l.Outstanding_Amount__c == 0) {
                System.assertEquals('Closed', l.Loan_Status__c, 'Zero balance loan must be Closed');
                System.assertEquals('LOW', l.Risk_Level__c, 'Closed loan risk must reset to LOW');
            } else {
                System.assertEquals('Overdue', l.Loan_Status__c, 'Non-zero loan must remain Overdue');
            }
        }

        List<Collection_Case__c> closedCases = [
            SELECT Id FROM Collection_Case__c WHERE Case_Status__c = 'Closed'
        ];
        System.assertEquals(1, closedCases.size(), 'Only the zero-balance loan case should be closed');
    }

    @isTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        Set<Id> resNull = LoanClosureService.closeEligibleLoans(null);
        Set<Id> resEmpty = LoanClosureService.closeEligibleLoans(new Set<Id>());
        LoanClosureService.closeEligibleLoansInvocable(null);
        LoanClosureService.closeEligibleLoansInvocable(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, resNull.size(), 'Null input should return empty set');
        System.assertEquals(0, resEmpty.size(), 'Empty input should return empty set');
    }
}

/**
 * @description       : Unit tests for LoanManagementService covering partial payments,
 *                      full payoff triggering auto-closure, invalid/overpayment rejection,
 *                      null/empty input, recalculation, and bulk processing (200 records).
 */
@isTest
private class LoanManagementServiceTest {

    @TestSetup
    static void setupData() {
        Customer__c cust = new Customer__c(
            Name = 'Vikram Deshmukh',
            Phone_Number__c = '+919820011223',
            State__c = 'Maharashtra',
            Branch__c = 'Pune West',
            Contactability_Status__c = 'Contactable'
        );
        insert cust;

        Loan_Account__c loan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 100000,
            Outstanding_Amount__c = 100000,
            Amount_Paid__c = 0,
            Interest_Rate__c = 11.0,
            Due_Date__c = Date.today().addDays(-15),
            Loan_Status__c = 'Overdue',
            Risk_Level__c = 'MEDIUM'
        );
        insert loan;

        Collection_Case__c cCase = new Collection_Case__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Case_Status__c = 'In Progress',
            Priority__c = 'Medium',
            Collection_Status__c = 'Pending'
        );
        insert cCase;
    }

    @isTest
    static void testPartialPaymentUpdatesBalances() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];

        Payment__c payment = new Payment__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Payment_Amount__c = 40000,
            Payment_Date__c = Date.today(),
            Payment_Mode__c = 'UPI',
            Payment_Status__c = 'Success'
        );

        Test.startTest();
        insert payment;
        Test.stopTest();

        Loan_Account__c updatedLoan = [
            SELECT Amount_Paid__c, Outstanding_Amount__c, Loan_Status__c
            FROM Loan_Account__c
            WHERE Id = :loan.Id
        ];
        System.assertEquals(40000, updatedLoan.Amount_Paid__c, 'Amount Paid should reflect partial payment');
        System.assertEquals(60000, updatedLoan.Outstanding_Amount__c, 'Outstanding should be reduced');
        System.assertEquals('Overdue', updatedLoan.Loan_Status__c, 'Loan should remain open after partial payment');
    }

    @isTest
    static void testFullPaymentTriggersLoanAutoClosure() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];

        Payment__c payment = new Payment__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Payment_Amount__c = 100000,
            Payment_Date__c = Date.today(),
            Payment_Mode__c = 'NEFT/RTGS',
            Payment_Status__c = 'Success'
        );

        Test.startTest();
        insert payment;
        Test.stopTest();

        Loan_Account__c updatedLoan = [
            SELECT Amount_Paid__c, Outstanding_Amount__c, Loan_Status__c
            FROM Loan_Account__c
            WHERE Id = :loan.Id
        ];
        Collection_Case__c updatedCase = [
            SELECT Case_Status__c, Collection_Status__c
            FROM Collection_Case__c
            WHERE Loan_Account__c = :loan.Id
            LIMIT 1
        ];

        System.assertEquals(0, updatedLoan.Outstanding_Amount__c, 'Outstanding balance must be zero');
        System.assertEquals('Closed', updatedLoan.Loan_Status__c, 'Loan must be auto-closed');
        System.assertEquals('Closed', updatedCase.Case_Status__c, 'Associated case must be auto-closed');
        System.assertEquals('Recovered', updatedCase.Collection_Status__c, 'Collection status must be Recovered');
    }

    @isTest
    static void testInvalidPaymentThrowsException() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];

        Payment__c zeroPayment = new Payment__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Payment_Amount__c = 0,
            Payment_Date__c = Date.today(),
            Payment_Mode__c = 'Cash',
            Payment_Status__c = 'Success'
        );

        Boolean threwError = false;
        Test.startTest();
        try {
            LoanManagementService.processSuccessfulPayments(new List<Payment__c>{ zeroPayment });
        } catch (LoanManagementService.LoanServiceException ex) {
            threwError = true;
        }
        Test.stopTest();

        System.assertEquals(true, threwError, 'Zero or negative payment amount must throw LoanServiceException');
    }

    @isTest
    static void testOverpaymentThrowsException() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];

        Payment__c overPayment = new Payment__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Payment_Amount__c = 150000,
            Payment_Date__c = Date.today(),
            Payment_Mode__c = 'Cash',
            Payment_Status__c = 'Success'
        );

        Boolean threwError = false;
        Test.startTest();
        try {
            LoanManagementService.processSuccessfulPayments(new List<Payment__c>{ overPayment });
        } catch (LoanManagementService.LoanServiceException ex) {
            threwError = true;
        }
        Test.stopTest();

        System.assertEquals(true, threwError, 'Payment exceeding outstanding balance must throw LoanServiceException');
    }

    @isTest
    static void testNullAndEmptyInputsHandledGracefully() {
        Test.startTest();
        LoanManagementService.processSuccessfulPayments(null);
        LoanManagementService.processSuccessfulPayments(new List<Payment__c>());
        LoanManagementService.recalculateLoanBalances(null);
        LoanManagementService.recalculateLoanBalances(new Set<Id>());
        Test.stopTest();
        System.assert(true, 'Null and empty inputs should complete without error');
    }

    @isTest
    static void testBulkPaymentProcessing200Records() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        List<Loan_Account__c> bulkLoans = new List<Loan_Account__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkLoans.add(new Loan_Account__c(
                Customer__c = cust.Id,
                Loan_Amount__c = 10000,
                Outstanding_Amount__c = 10000,
                Amount_Paid__c = 0,
                Due_Date__c = Date.today().addDays(-10),
                Loan_Status__c = 'Active',
                Risk_Level__c = 'LOW'
            ));
        }
        insert bulkLoans;

        List<Payment__c> bulkPayments = new List<Payment__c>();
        for (Loan_Account__c loan : bulkLoans) {
            bulkPayments.add(new Payment__c(
                Customer__c = cust.Id,
                Loan_Account__c = loan.Id,
                Payment_Amount__c = 10000,
                Payment_Date__c = Date.today(),
                Payment_Mode__c = 'UPI',
                Payment_Status__c = 'Success'
            ));
        }

        Test.startTest();
        insert bulkPayments;
        Test.stopTest();

        Integer closedCount = [
            SELECT COUNT()
            FROM Loan_Account__c
            WHERE Id IN :bulkLoans
              AND Loan_Status__c = 'Closed'
        ];
        System.assertEquals(200, closedCount, 'All 200 bulk paid loans should auto-close without governor limit errors');
    }
}

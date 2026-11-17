/**
 * @description       : Verifies zero outstanding balance on Loan_Account__c records,
 *                      transitions eligible loans to Closed, and closes associated
 *                      open Collection_Case__c records in bulk.
 * @group             : Collections Management
 */
public with sharing class LoanClosureService {

    public class LoanClosureException extends Exception {}

    /**
     * @description Invocable wrapper allowing Salesforce Flows (Loan_Auto_Closure)
     *              to invoke bulk-safe loan closure.
     * @param loanIds List of Loan_Account__c IDs from Flow
     */
    @InvocableMethod(
        label='Close Eligible Loans'
        description='Verifies zero outstanding balance, marks Loan Account Closed, and closes open Collection Cases.'
        category='Collections Management'
    )
    public static void closeEligibleLoansInvocable(List<Id> loanIds) {
        if (loanIds == null || loanIds.isEmpty()) {
            return;
        }
        closeEligibleLoans(new Set<Id>(loanIds));
    }

    /**
     * @description Closes Loan_Account__c records with Outstanding_Amount__c <= 0
     *              and closes any associated open Collection_Case__c records.
     * @param loanAccountIds Set of Loan_Account__c IDs to evaluate
     * @return Set<Id> IDs of loans that were closed
     */
    public static Set<Id> closeEligibleLoans(Set<Id> loanAccountIds) {
        Set<Id> closedLoanIds = new Set<Id>();
        if (loanAccountIds == null || loanAccountIds.isEmpty()) {
            return closedLoanIds;
        }

        if (!Schema.sObjectType.Loan_Account__c.isUpdateable() ||
            !Schema.sObjectType.Collection_Case__c.isUpdateable()) {
            throw new LoanClosureException('Insufficient permissions to close loans or collection cases.');
        }

        List<Loan_Account__c> loans = [
            SELECT Id, Outstanding_Amount__c, Loan_Status__c, Risk_Level__c
            FROM Loan_Account__c
            WHERE Id IN :loanAccountIds
            WITH SECURITY_ENFORCED
        ];

        List<Loan_Account__c> loansToClose = new List<Loan_Account__c>();
        for (Loan_Account__c loan : loans) {
            Decimal outstanding = loan.Outstanding_Amount__c != null ? loan.Outstanding_Amount__c : 0;
            if (outstanding <= 0 && loan.Loan_Status__c != 'Closed') {
                loan.Loan_Status__c = 'Closed';
                loan.Outstanding_Amount__c = 0;
                loan.Risk_Level__c = 'LOW';
                loansToClose.add(loan);
                closedLoanIds.add(loan.Id);
            }
        }

        if (!loansToClose.isEmpty()) {
            SObjectAccessDecision loanDecision = Security.stripInaccessible(AccessType.UPDATABLE, loansToClose);
            update loanDecision.getRecords();
        }

        // Also check cases for any loan in the input set that already has Outstanding_Amount__c == 0
        Set<Id> zeroBalanceLoanIds = new Set<Id>(closedLoanIds);
        for (Loan_Account__c loan : loans) {
            if (loan.Outstanding_Amount__c != null && loan.Outstanding_Amount__c <= 0) {
                zeroBalanceLoanIds.add(loan.Id);
            }
        }

        if (!zeroBalanceLoanIds.isEmpty()) {
            List<Collection_Case__c> openCases = [
                SELECT Id, Case_Status__c, Collection_Status__c, Loan_Account__c
                FROM Collection_Case__c
                WHERE Loan_Account__c IN :zeroBalanceLoanIds
                  AND Case_Status__c != 'Closed'
                WITH SECURITY_ENFORCED
            ];

            List<Collection_Case__c> casesToClose = new List<Collection_Case__c>();
            for (Collection_Case__c cCase : openCases) {
                cCase.Case_Status__c = 'Closed';
                cCase.Collection_Status__c = 'Recovered';
                casesToClose.add(cCase);
            }

            if (!casesToClose.isEmpty()) {
                SObjectAccessDecision caseDecision = Security.stripInaccessible(AccessType.UPDATABLE, casesToClose);
                update caseDecision.getRecords();
            }
        }

        return closedLoanIds;
    }
}

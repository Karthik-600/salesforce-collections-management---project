/**
 * @description       : Core business logic service for Loan_Account__c and Payment__c processing.
 *                      Handles bulk-safe payment validation, balance recalculation, and
 *                      delegates eligible zero-balance loans to LoanClosureService.
 * @group             : Collections Management
 */
public with sharing class LoanManagementService {

    public class LoanServiceException extends Exception {}

    /**
     * @description Processes a list of successful Payment__c records in bulk,
     *              updating Amount_Paid__c and Outstanding_Amount__c on parent Loan_Account__c records,
     *              and invoking LoanClosureService for loans that reach zero outstanding balance.
     * @param payments List of Payment__c records to process
     */
    public static void processSuccessfulPayments(List<Payment__c> payments) {
        if (payments == null || payments.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Loan_Account__c.isUpdateable()) {
            throw new LoanServiceException('Insufficient permissions to update Loan Account balances.');
        }

        Map<Id, Decimal> paymentTotalsByLoanId = new Map<Id, Decimal>();
        for (Payment__c payment : payments) {
            if (payment == null || payment.Loan_Account__c == null) {
                continue;
            }
            if (payment.Payment_Status__c != 'Success') {
                continue;
            }
            if (payment.Payment_Amount__c == null || payment.Payment_Amount__c <= 0) {
                throw new LoanServiceException('Payment amount must be greater than zero.');
            }
            Decimal currentTotal = paymentTotalsByLoanId.containsKey(payment.Loan_Account__c)
                ? paymentTotalsByLoanId.get(payment.Loan_Account__c)
                : 0;
            paymentTotalsByLoanId.put(payment.Loan_Account__c, currentTotal + payment.Payment_Amount__c);
        }

        if (paymentTotalsByLoanId.isEmpty()) {
            return;
        }

        Map<Id, Loan_Account__c> loansById = new Map<Id, Loan_Account__c>([
            SELECT Id, Loan_Amount__c, Outstanding_Amount__c, Amount_Paid__c, Loan_Status__c
            FROM Loan_Account__c
            WHERE Id IN :paymentTotalsByLoanId.keySet()
            WITH SECURITY_ENFORCED
            FOR UPDATE
        ]);

        List<Loan_Account__c> loansToUpdate = new List<Loan_Account__c>();
        Set<Id> loansEligibleForClosure = new Set<Id>();

        for (Id loanId : paymentTotalsByLoanId.keySet()) {
            Loan_Account__c loan = loansById.get(loanId);
            if (loan == null) {
                continue;
            }

            Decimal paidIncrement = paymentTotalsByLoanId.get(loanId);
            Decimal existingPaid = loan.Amount_Paid__c != null ? loan.Amount_Paid__c : 0;
            Decimal existingOutstanding = loan.Outstanding_Amount__c != null
                ? loan.Outstanding_Amount__c
                : (loan.Loan_Amount__c != null ? loan.Loan_Amount__c : 0);

            if (paidIncrement > existingOutstanding) {
                throw new LoanServiceException(
                    'Payment amount (' + paidIncrement + ') exceeds current outstanding balance (' + existingOutstanding + ').'
                );
            }

            loan.Amount_Paid__c = existingPaid + paidIncrement;
            loan.Outstanding_Amount__c = Math.max(0, existingOutstanding - paidIncrement);
            loansToUpdate.add(loan);

            if (loan.Outstanding_Amount__c == 0) {
                loansEligibleForClosure.add(loan.Id);
            }
        }

        if (!loansToUpdate.isEmpty()) {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, loansToUpdate);
            update decision.getRecords();
        }

        if (!loansEligibleForClosure.isEmpty()) {
            LoanClosureService.closeEligibleLoans(loansEligibleForClosure);
        }
    }

    /**
     * @description Recalculates exact Amount_Paid__c and Outstanding_Amount__c from all Success
     *              Payment__c records for the given Loan_Account__c IDs. Useful for batch reconciliation
     *              and payment reversals.
     * @param loanIds Set of Loan_Account__c IDs to recalculate
     */
    public static void recalculateLoanBalances(Set<Id> loanIds) {
        if (loanIds == null || loanIds.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Loan_Account__c.isUpdateable() ||
            !Schema.sObjectType.Payment__c.isAccessible()) {
            throw new LoanServiceException('Insufficient permissions to recalculate loan balances.');
        }

        Map<Id, Decimal> totalSuccessPaymentsByLoan = new Map<Id, Decimal>();
        for (AggregateResult agg : [
            SELECT Loan_Account__c loanId, SUM(Payment_Amount__c) totalPaid
            FROM Payment__c
            WHERE Loan_Account__c IN :loanIds
              AND Payment_Status__c = 'Success'
            GROUP BY Loan_Account__c
        ]) {
            Id loanId = (Id) agg.get('loanId');
            Decimal totalPaid = (Decimal) agg.get('totalPaid');
            totalSuccessPaymentsByLoan.put(loanId, totalPaid != null ? totalPaid : 0);
        }

        List<Loan_Account__c> loans = [
            SELECT Id, Loan_Amount__c, Amount_Paid__c, Outstanding_Amount__c, Loan_Status__c
            FROM Loan_Account__c
            WHERE Id IN :loanIds
            WITH SECURITY_ENFORCED
        ];

        List<Loan_Account__c> loansToUpdate = new List<Loan_Account__c>();
        Set<Id> closureCandidates = new Set<Id>();

        for (Loan_Account__c loan : loans) {
            Decimal loanPrincipal = loan.Loan_Amount__c != null ? loan.Loan_Amount__c : 0;
            Decimal totalPaid = totalSuccessPaymentsByLoan.containsKey(loan.Id)
                ? totalSuccessPaymentsByLoan.get(loan.Id)
                : 0;
            Decimal remaining = Math.max(0, loanPrincipal - totalPaid);

            loan.Amount_Paid__c = totalPaid;
            loan.Outstanding_Amount__c = remaining;
            loansToUpdate.add(loan);

            if (remaining == 0 && loan.Loan_Status__c != 'Closed') {
                closureCandidates.add(loan.Id);
            }
        }

        if (!loansToUpdate.isEmpty()) {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, loansToUpdate);
            update decision.getRecords();
        }

        if (!closureCandidates.isEmpty()) {
            LoanClosureService.closeEligibleLoans(closureCandidates);
        }
    }
}

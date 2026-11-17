/**
 * @description       : Trigger on Payment__c delegating to LoanManagementService
 *                      to update parent Loan_Account__c balances and trigger auto-closure
 *                      when Payment_Status__c transitions to Success.
 */
trigger PaymentTrigger on Payment__c (after insert, after update) {
    List<Payment__c> newlySucceededPayments = new List<Payment__c>();

    if (Trigger.isInsert) {
        for (Payment__c payment : Trigger.new) {
            if (payment.Payment_Status__c == 'Success') {
                newlySucceededPayments.add(payment);
            }
        }
    } else if (Trigger.isUpdate) {
        for (Payment__c payment : Trigger.new) {
            Payment__c oldPayment = Trigger.oldMap.get(payment.Id);
            if (payment.Payment_Status__c == 'Success' && oldPayment.Payment_Status__c != 'Success') {
                newlySucceededPayments.add(payment);
            }
        }
    }

    if (!newlySucceededPayments.isEmpty()) {
        LoanManagementService.processSuccessfulPayments(newlySucceededPayments);
    }
}

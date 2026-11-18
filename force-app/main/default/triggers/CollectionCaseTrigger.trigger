/**
 * @description       : Trigger on Collection_Case__c delegating to TelecallerAssignmentService
 *                      to auto-assign active telecallers to unassigned cases before insert.
 */
trigger CollectionCaseTrigger on Collection_Case__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TelecallerAssignmentService.assignTelecallers(Trigger.new);
    }
}

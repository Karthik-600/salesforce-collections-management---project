/**
 * @description       : Assigns Collection_Case__c records to active telecallers using a
 *                      configurable strategy (LEAST_LOADED or ROUND_ROBIN).
 *                      Strictly excludes inactive users.
 * @group             : Collections Management
 */
public with sharing class TelecallerAssignmentService {

    public enum AssignmentStrategy {
        LEAST_LOADED,
        ROUND_ROBIN
    }

    @TestVisible
    private static AssignmentStrategy activeStrategy = AssignmentStrategy.LEAST_LOADED;

    /**
     * @description Assigns telecallers to unassigned Collection_Case__c records in memory
     *              (suitable for Before Insert / Before Update triggers without extra DML).
     * @param cases List of Collection_Case__c records
     */
    public static void assignTelecallers(List<Collection_Case__c> cases) {
        if (cases == null || cases.isEmpty()) {
            return;
        }

        List<Collection_Case__c> unassignedCases = new List<Collection_Case__c>();
        for (Collection_Case__c cCase : cases) {
            if (cCase != null && cCase.Assigned_Telecaller__c == null && cCase.Case_Status__c != 'Closed') {
                unassignedCases.add(cCase);
            }
        }

        if (unassignedCases.isEmpty()) {
            return;
        }

        List<User> activeTelecallers = getActiveTelecallers();
        if (activeTelecallers.isEmpty()) {
            return;
        }

        if (activeStrategy == AssignmentStrategy.ROUND_ROBIN) {
            assignRoundRobin(unassignedCases, activeTelecallers);
        } else {
            assignLeastLoaded(unassignedCases, activeTelecallers);
        }
    }

    /**
     * @description Queries active users assigned to the Telecaller_Access permission set
     *              (or active standard users as fallback if permission set is not yet assigned).
     *              Always enforces IsActive = true.
     * @return List<User> Active eligible telecallers
     */
    @TestVisible
    private static List<User> getActiveTelecallers() {
        Set<Id> telecallerUserIds = new Set<Id>();

        for (PermissionSetAssignment psa : [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = 'Telecaller_Access'
              AND Assignee.IsActive = true
        ]) {
            telecallerUserIds.add(psa.AssigneeId);
        }

        if (!telecallerUserIds.isEmpty()) {
            return [
                SELECT Id, Name
                FROM User
                WHERE Id IN :telecallerUserIds
                  AND IsActive = true
                ORDER BY Name ASC
            ];
        }

        // Fallback for scratch orgs / initial dev setup where permission set is not assigned yet
        return [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true
              AND UserType = 'Standard'
            ORDER BY CreatedDate ASC
            LIMIT 50
        ];
    }

    private static void assignRoundRobin(List<Collection_Case__c> unassignedCases, List<User> telecallers) {
        Integer idx = 0;
        Integer poolSize = telecallers.size();
        for (Collection_Case__c cCase : unassignedCases) {
            cCase.Assigned_Telecaller__c = telecallers[Math.mod(idx, poolSize)].Id;
            idx++;
        }
    }

    private static void assignLeastLoaded(List<Collection_Case__c> unassignedCases, List<User> telecallers) {
        Map<Id, Integer> openCaseCountByUser = new Map<Id, Integer>();
        for (User u : telecallers) {
            openCaseCountByUser.put(u.Id, 0);
        }

        for (AggregateResult agg : [
            SELECT Assigned_Telecaller__c telecallerId, COUNT(Id) openCount
            FROM Collection_Case__c
            WHERE Assigned_Telecaller__c IN :openCaseCountByUser.keySet()
              AND Case_Status__c != 'Closed'
            GROUP BY Assigned_Telecaller__c
        ]) {
            Id userId = (Id) agg.get('telecallerId');
            Integer countVal = (Integer) agg.get('openCount');
            openCaseCountByUser.put(userId, countVal);
        }

        for (Collection_Case__c cCase : unassignedCases) {
            Id selectedUserId = findLeastLoadedUser(openCaseCountByUser);
            cCase.Assigned_Telecaller__c = selectedUserId;
            openCaseCountByUser.put(selectedUserId, openCaseCountByUser.get(selectedUserId) + 1);
        }
    }

    private static Id findLeastLoadedUser(Map<Id, Integer> countsByUser) {
        Id bestUserId = null;
        Integer lowestCount = null;
        for (Id userId : countsByUser.keySet()) {
            Integer current = countsByUser.get(userId);
            if (lowestCount == null || current < lowestCount) {
                lowestCount = current;
                bestUserId = userId;
            }
        }
        return bestUserId;
    }
}

/**
 * @description       : Unit tests for TelecallerAssignmentService covering LEAST_LOADED,
 *                      ROUND_ROBIN, inactive user exclusion, already-assigned preservation,
 *                      null input handling, and bulk assignment.
 */
@isTest
private class TelecallerAssignmentServiceTest {

    @TestSetup
    static void setupData() {
        Customer__c cust = new Customer__c(
            Name = 'Ananya Reddy',
            Phone_Number__c = '+919900112233',
            State__c = 'Telangana',
            Branch__c = 'Hyderabad',
            Contactability_Status__c = 'Contactable'
        );
        insert cust;

        Loan_Account__c loan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 250000,
            Outstanding_Amount__c = 200000,
            Amount_Paid__c = 50000,
            Due_Date__c = Date.today().addDays(-20),
            Loan_Status__c = 'Overdue',
            Risk_Level__c = 'MEDIUM'
        );
        insert loan;
    }

    @isTest
    static void testLeastLoadedAssignmentAssignsActiveUser() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];

        Collection_Case__c cCase = new Collection_Case__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Case_Status__c = 'New',
            Priority__c = 'High',
            Collection_Status__c = 'Pending'
        );

        TelecallerAssignmentService.activeStrategy = TelecallerAssignmentService.AssignmentStrategy.LEAST_LOADED;

        Test.startTest();
        insert cCase;
        Test.stopTest();

        Collection_Case__c insertedCase = [
            SELECT Assigned_Telecaller__c, Assigned_Telecaller__r.IsActive
            FROM Collection_Case__c
            WHERE Id = :cCase.Id
        ];
        System.assertNotEquals(null, insertedCase.Assigned_Telecaller__c, 'Telecaller should be auto-assigned');
        System.assertEquals(true, insertedCase.Assigned_Telecaller__r.IsActive, 'Assigned telecaller must be active');
    }

    @isTest
    static void testRoundRobinBulkAssignment() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];

        List<Collection_Case__c> bulkCases = new List<Collection_Case__c>();
        for (Integer i = 0; i < 50; i++) {
            bulkCases.add(new Collection_Case__c(
                Customer__c = cust.Id,
                Loan_Account__c = loan.Id,
                Case_Status__c = 'New',
                Priority__c = 'Medium',
                Collection_Status__c = 'Pending'
            ));
        }

        TelecallerAssignmentService.activeStrategy = TelecallerAssignmentService.AssignmentStrategy.ROUND_ROBIN;

        Test.startTest();
        insert bulkCases;
        Test.stopTest();

        Integer assignedCount = [
            SELECT COUNT()
            FROM Collection_Case__c
            WHERE Id IN :bulkCases
              AND Assigned_Telecaller__c != null
        ];
        System.assertEquals(50, assignedCount, 'All 50 bulk cases should be assigned');
    }

    @isTest
    static void testPreservesExistingAssignmentAndHandlesNull() {
        Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
        Loan_Account__c loan = [SELECT Id FROM Loan_Account__c LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        Collection_Case__c preAssigned = new Collection_Case__c(
            Customer__c = cust.Id,
            Loan_Account__c = loan.Id,
            Assigned_Telecaller__c = currentUserId,
            Case_Status__c = 'In Progress',
            Priority__c = 'Low',
            Collection_Status__c = 'Pending'
        );

        Test.startTest();
        TelecallerAssignmentService.assignTelecallers(null);
        TelecallerAssignmentService.assignTelecallers(new List<Collection_Case__c>());
        insert preAssigned;
        Test.stopTest();

        Collection_Case__c result = [
            SELECT Assigned_Telecaller__c
            FROM Collection_Case__c
            WHERE Id = :preAssigned.Id
        ];
        System.assertEquals(currentUserId, result.Assigned_Telecaller__c, 'Pre-assigned telecaller must not be overwritten');
    }
}

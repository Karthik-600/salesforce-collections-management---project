/**
 * @description       : Unit tests for SlackNotificationService and DailyCollectionSummaryInvocable
 *                      using SlackHttpCalloutMock for both 200 OK and 500 Error responses.
 */
@isTest
private class SlackNotificationServiceTest {

    @isTest
    static void testSendEscalationAndFieldVisitNotifications() {
        SlackHttpCalloutMock.reset();
        Test.setMock(HttpCalloutMock.class, new SlackHttpCalloutMock(200, '{"ok": true}'));

        SlackNotificationService.SlackNotificationRequest escalationReq =
            SlackNotificationService.buildEscalationRequest(
                null,
                'CC-00012',
                'Rajesh Kumar',
                'LN-0025',
                'Arun Executive',
                'Repeated broken promises to pay'
            );

        SlackNotificationService.SlackNotificationRequest visitReq =
            SlackNotificationService.buildFieldVisitRequest(
                null,
                'FV-00044',
                'Rajesh Kumar',
                'LN-0025',
                'Arun Executive',
                13.082680,
                80.270718,
                'Completed'
            );

        Test.startTest();
        SlackNotificationService.sendNotificationsFromFlow(
            new List<SlackNotificationService.SlackNotificationRequest>{ escalationReq, visitReq }
        );
        Test.stopTest();

        System.assertEquals(2, SlackHttpCalloutMock.capturedRequests.size(), 'Two Slack callouts should be executed');
        System.assertEquals(
            SlackNotificationService.NAMED_CREDENTIAL_PREFIX,
            SlackHttpCalloutMock.capturedRequests[0].getEndpoint(),
            'Endpoint must use Named Credential'
        );
    }

    @isTest
    static void testDailySummaryInvocableDispatchesToSlack() {
        Customer__c cust = new Customer__c(Name = 'Summary Customer', Phone_Number__c = '+919000123456');
        insert cust;

        Loan_Account__c loan = new Loan_Account__c(
            Customer__c = cust.Id,
            Loan_Amount__c = 100000,
            Outstanding_Amount__c = 50000,
            Amount_Paid__c = 50000,
            Due_Date__c = Date.today().addDays(-5),
            Loan_Status__c = 'Overdue'
        );
        insert loan;

        insert new List<Collection_Case__c>{
            new Collection_Case__c(Customer__c = cust.Id, Loan_Account__c = loan.Id, Case_Status__c = 'Closed', Priority__c = 'Low'),
            new Collection_Case__c(Customer__c = cust.Id, Loan_Account__c = loan.Id, Case_Status__c = 'In Progress', Priority__c = 'Medium'),
            new Collection_Case__c(Customer__c = cust.Id, Loan_Account__c = loan.Id, Case_Status__c = 'Escalated', Priority__c = 'Critical', Escalation_Reason__c = 'No response')
        };

        SlackHttpCalloutMock.reset();
        Test.setMock(HttpCalloutMock.class, new SlackHttpCalloutMock(200, '{"ok": true}'));

        Test.startTest();
        List<DailyCollectionSummaryInvocable.SummaryOutput> outputs =
            DailyCollectionSummaryInvocable.executeDailySummary();
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Should return one summary output');
        System.assertEquals(3, outputs[0].totalCases, 'Total cases should be 3');
        System.assertEquals(1, outputs[0].closedCases, 'Closed cases should be 1');
        System.assertEquals(1, outputs[0].pendingCases, 'Pending cases should be 1');
        System.assertEquals(1, outputs[0].escalatedCases, 'Escalated cases should be 1');
        System.assertEquals(1, SlackHttpCalloutMock.capturedRequests.size(), 'Summary Slack callout should fire');
    }

    @isTest
    static void testSlackErrorResponseAndEmptyPayload() {
        SlackHttpCalloutMock.reset();
        Test.setMock(HttpCalloutMock.class, new SlackHttpCalloutMock(500, '{"ok": false, "error": "server_error"}'));

        SlackNotificationService.SlackNotificationRequest req =
            SlackNotificationService.buildDailySummaryRequest(10, 4, 4, 2);

        Boolean threwHttpError = false;
        Test.startTest();
        try {
            SlackNotificationService.sendSlackPayload(req);
        } catch (SlackNotificationService.SlackNotificationException ex) {
            threwHttpError = true;
        }
        Test.stopTest();

        System.assertEquals(true, threwHttpError, 'HTTP 500 must throw SlackNotificationException');

        Boolean threwEmptyError = false;
        try {
            SlackNotificationService.sendSlackPayload(null);
        } catch (SlackNotificationService.SlackNotificationException ex) {
            threwEmptyError = true;
        }
        System.assertEquals(true, threwEmptyError, 'Null payload must throw SlackNotificationException');
    }
}

/**
 * @description       : Invocable Apex action invoked by the 6 PM Scheduled Flow
 *                      (Daily_Collection_Summary_Slack). Aggregates total, closed,
 *                      pending, and escalated Collection_Case__c records and posts
 *                      the summary to #daily-collection-summary via SlackNotificationService.
 * @group             : Collections Management
 */
public with sharing class DailyCollectionSummaryInvocable {

    public class SummaryOutput {
        @InvocableVariable(label='Total Cases')
        public Integer totalCases;

        @InvocableVariable(label='Closed Cases')
        public Integer closedCases;

        @InvocableVariable(label='Pending Cases')
        public Integer pendingCases;

        @InvocableVariable(label='Escalated Cases')
        public Integer escalatedCases;
    }

    @InvocableMethod(
        label='Calculate and Send Daily Collection Summary'
        description='Aggregates Collection Case metrics and dispatches a Slack summary to #daily-collection-summary.'
        category='Collections Management'
    )
    public static List<SummaryOutput> executeDailySummary() {
        Integer totalCases = 0;
        Integer closedCases = 0;
        Integer pendingCases = 0;
        Integer escalatedCases = 0;

        if (Schema.sObjectType.Collection_Case__c.isAccessible()) {
            for (AggregateResult agg : [
                SELECT Case_Status__c status, COUNT(Id) caseCount
                FROM Collection_Case__c
                GROUP BY Case_Status__c
            ]) {
                String status = (String) agg.get('status');
                Integer countVal = (Integer) agg.get('caseCount');
                totalCases += countVal;

                if (status == 'Closed') {
                    closedCases += countVal;
                } else if (status == 'Escalated') {
                    escalatedCases += countVal;
                } else {
                    pendingCases += countVal;
                }
            }
        }

        SlackNotificationService.SlackNotificationRequest slackReq =
            SlackNotificationService.buildDailySummaryRequest(
                totalCases,
                closedCases,
                pendingCases,
                escalatedCases
            );

        SlackNotificationService.sendNotificationsFromFlow(
            new List<SlackNotificationService.SlackNotificationRequest>{ slackReq }
        );

        SummaryOutput output = new SummaryOutput();
        output.totalCases = totalCases;
        output.closedCases = closedCases;
        output.pendingCases = pendingCases;
        output.escalatedCases = escalatedCases;

        return new List<SummaryOutput>{ output };
    }
}

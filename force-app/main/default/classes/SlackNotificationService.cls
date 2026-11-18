/**
 * @description       : Secure Slack notification service using Salesforce Named Credentials.
 *                      NEVER hardcodes webhook URLs, OAuth tokens, or secrets.
 *                      Supports:
 *                      - #collection-manager-alerts (Case Escalation)
 *                      - #daily-collection-summary (6 PM Daily Summary)
 *                      - #field-executive-updates (Field Visit GPS Verification)
 * @group             : Collections Management
 */
public with sharing class SlackNotificationService {

    public static final String NAMED_CREDENTIAL_PREFIX = 'callout:Slack_Collections_Webhook';
    public static final String CHANNEL_MANAGER_ALERTS = '#collection-manager-alerts';
    public static final String CHANNEL_DAILY_SUMMARY = '#daily-collection-summary';
    public static final String CHANNEL_FIELD_UPDATES = '#field-executive-updates';

    public class SlackNotificationException extends Exception {}

    /**
     * @description Invocable request structure for Salesforce Record-Triggered & Scheduled Flows.
     */
    public class SlackNotificationRequest {
        @InvocableVariable(label='Channel Name' description='Target Slack channel (e.g., #collection-manager-alerts)' required=true)
        public String channel;

        @InvocableVariable(label='Notification Type' description='CASE_ESCALATION, DAILY_SUMMARY, or FIELD_VISIT' required=true)
        public String notificationType;

        @InvocableVariable(label='Message Body' description='Formatted text payload to send to Slack' required=true)
        public String messageBody;

        @InvocableVariable(label='Record ID' description='Optional Salesforce Record ID for reference')
        public Id recordId;
    }

    /**
     * @description Invocable entry point for Salesforce Flows.
     *              Enqueues a Queueable job so HTTP callouts execute safely after DML commits.
     * @param requests List of SlackNotificationRequest from Flow
     */
    @InvocableMethod(
        label='Send Slack Collection Notification'
        description='Dispatches formatted notifications to Slack channels via Named Credential.'
        category='Collections Management'
    )
    public static void sendNotificationsFromFlow(List<SlackNotificationRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        System.enqueueJob(new SlackDispatchQueueable(requests));
    }

    /**
     * @description Convenience helper to format and send a Case Escalation alert
     *              to #collection-manager-alerts.
     */
    public static SlackNotificationRequest buildEscalationRequest(
        Id caseId,
        String caseNumber,
        String customerName,
        String loanNumber,
        String executiveName,
        String escalationReason
    ) {
        SlackNotificationRequest req = new SlackNotificationRequest();
        req.channel = CHANNEL_MANAGER_ALERTS;
        req.notificationType = 'CASE_ESCALATION';
        req.recordId = caseId;
        req.messageBody =
            '*Case Escalation Alert* [' + safeStr(caseNumber) + ']\n' +
            '• Customer: ' + safeStr(customerName) + '\n' +
            '• Loan Account: ' + safeStr(loanNumber) + '\n' +
            '• Assigned Executive: ' + safeStr(executiveName) + '\n' +
            '• Escalation Reason: ' + safeStr(escalationReason);
        return req;
    }

    /**
     * @description Convenience helper to format a Daily Collection Summary
     *              for #daily-collection-summary.
     */
    public static SlackNotificationRequest buildDailySummaryRequest(
        Integer totalCases,
        Integer closedCases,
        Integer pendingCases,
        Integer escalatedCases
    ) {
        SlackNotificationRequest req = new SlackNotificationRequest();
        req.channel = CHANNEL_DAILY_SUMMARY;
        req.notificationType = 'DAILY_SUMMARY';
        req.messageBody =
            '*Daily Collection Summary (' + Date.today().format() + ')*\n' +
            '• Total Cases: ' + String.valueOf(totalCases != null ? totalCases : 0) + '\n' +
            '• Closed Cases: ' + String.valueOf(closedCases != null ? closedCases : 0) + '\n' +
            '• Pending Cases: ' + String.valueOf(pendingCases != null ? pendingCases : 0) + '\n' +
            '• Escalated Cases: ' + String.valueOf(escalatedCases != null ? escalatedCases : 0);
        return req;
    }

    /**
     * @description Convenience helper to format a Field Visit verification alert
     *              for #field-executive-updates.
     */
    public static SlackNotificationRequest buildFieldVisitRequest(
        Id visitId,
        String visitRef,
        String customerName,
        String loanNumber,
        String executiveName,
        Decimal latitude,
        Decimal longitude,
        String visitStatus
    ) {
        SlackNotificationRequest req = new SlackNotificationRequest();
        req.channel = CHANNEL_FIELD_UPDATES;
        req.notificationType = 'FIELD_VISIT';
        req.recordId = visitId;
        String coords = (latitude != null && longitude != null)
            ? String.valueOf(latitude) + ', ' + String.valueOf(longitude)
            : 'GPS Not Captured';
        req.messageBody =
            '*Field Visit Update* [' + safeStr(visitRef) + ']\n' +
            '• Customer: ' + safeStr(customerName) + '\n' +
            '• Loan Account: ' + safeStr(loanNumber) + '\n' +
            '• Field Executive: ' + safeStr(executiveName) + '\n' +
            '• Status: ' + safeStr(visitStatus) + '\n' +
            '• GPS Coordinates: ' + coords;
        return req;
    }

    /**
     * @description Executes the actual HTTP POST callout to Slack via Named Credential.
     * @param req SlackNotificationRequest payload
     * @return HttpResponse
     */
    public static HttpResponse sendSlackPayload(SlackNotificationRequest req) {
        if (req == null || String.isBlank(req.messageBody)) {
            throw new SlackNotificationException('Slack notification payload cannot be empty.');
        }

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(NAMED_CREDENTIAL_PREFIX);
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json; charset=UTF-8');
        httpReq.setTimeout(15000);

        Map<String, Object> bodyMap = new Map<String, Object>{
            'channel' => String.isNotBlank(req.channel) ? req.channel : CHANNEL_MANAGER_ALERTS,
            'text' => req.messageBody
        };
        httpReq.setBody(JSON.serialize(bodyMap));

        Http http = new Http();
        HttpResponse res = http.send(httpReq);

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new SlackNotificationException(
                'Slack API callout failed with HTTP ' + res.getStatusCode() + ': ' + res.getBody()
            );
        }

        return res;
    }

    private static String safeStr(String val) {
        return String.isNotBlank(val) ? val : 'N/A';
    }

    /**
     * @description Queueable worker that dispatches Slack HTTP callouts asynchronously.
     */
    public class SlackDispatchQueueable implements Queueable, Database.AllowsCallouts {
        private List<SlackNotificationRequest> requests;

        public SlackDispatchQueueable(List<SlackNotificationRequest> requests) {
            this.requests = requests;
        }

        public void execute(QueueableContext context) {
            if (requests == null || requests.isEmpty()) {
                return;
            }
            for (SlackNotificationRequest req : requests) {
                try {
                    sendSlackPayload(req);
                } catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR, 'SlackNotificationService callout error: ' + ex.getMessage());
                }
            }
        }
    }
}

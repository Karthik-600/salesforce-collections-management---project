# Slack Integration Architecture & Setup

## Overview

Salesforce acts as the system of record for loans, telecaller updates, and field visits. Slack acts as the real-time managerial notification layer across three dedicated channels:

1. **`#collection-manager-alerts`** — Real-time alerts when a `Collection_Case__c` is marked `Escalated` (includes Customer, Loan, Assigned Executive, and Escalation Reason).
2. **`#daily-collection-summary`** — Daily 6:00 PM performance digest showing Total, Closed, Pending, and Escalated cases.
3. **`#field-executive-updates`** — Real-time updates when a Field Executive records a `Field_Visit__c` with GPS Latitude/Longitude coordinates.

## Security Model (Zero Hardcoded Secrets)

`SlackNotificationService.cls` **never** stores webhook URLs, OAuth tokens, or signing secrets in Apex code or metadata. All HTTP POST requests target:

```apex
callout:Slack_Collections_Webhook
```

A placeholder template is included at `force-app/main/default/namedCredentials/Slack_Collections_Webhook.namedCredential-meta.xml`.

## Manual Org Configuration Steps

### Step 1: Create a Slack App & Webhook / Bot Token
1. Open [api.slack.com/apps](https://api.slack.com/apps) and create a Slack App for your workspace.
2. Either enable **Incoming Webhooks** (for single-channel routing) OR configure a **Bot Token** (`chat:write` scope) targeting `https://slack.com/api/chat.postMessage` so the `channel` JSON field routes dynamically to `#collection-manager-alerts`, `#daily-collection-summary`, and `#field-executive-updates`.
3. Invite the Slack App bot to all three channels.

### Step 2: Configure Salesforce Named Credential
1. Navigate to **Setup → Security → Named Credentials**.
2. Open **Slack Collections Webhook** (`Slack_Collections_Webhook`).
3. Update the **URL** to your real Slack Incoming Webhook URL or `https://slack.com/api/chat.postMessage`.
4. If using `chat.postMessage`, configure an **External Credential** with a custom `Authorization: Bearer <BotToken>` header using Named Principals.
5. Grant External Credential Principal Access to `Collections_Manager_Access`, `Telecaller_Access`, and `Field_Executive_Access` permission sets.

## Testing & Mocking

Unit tests use `SlackHttpCalloutMock.cls` (`HttpCalloutMock`) to verify both HTTP 200 success payloads and HTTP 500 error handling without making real outbound calls.

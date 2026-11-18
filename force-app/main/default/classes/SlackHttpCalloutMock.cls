/**
 * @description       : Reusable HttpCalloutMock for testing SlackNotificationService
 *                      without making real external HTTP requests.
 * @group             : Collections Management Tests
 */
@isTest
public class SlackHttpCalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;
    public static List<HttpRequest> capturedRequests = new List<HttpRequest>();

    public SlackHttpCalloutMock() {
        this(200, '{"ok": true}');
    }

    public SlackHttpCalloutMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public HttpResponse respond(HttpRequest req) {
        capturedRequests.add(req);
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.statusCode);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.responseBody);
        return res;
    }

    public static void reset() {
        capturedRequests.clear();
    }
}

@RestResource(urlMapping='/AccountIntegration/*')
global with sharing class AccountWebService {

    @HttpPost
    global static void handleIncomingAccount() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {

            String body =
                (req.requestBody != null)
                ? req.requestBody.toString()
                : '';

            if (String.isBlank(body)) {
                sendResponse(res, 400, 'Empty request body.',null);
                return;
            }

            // Create integration log
            Integration_Log__c log = new Integration_Log__c(
                Payload__c = body,
                Status__c = 'Pending'
            );
            insert log;

            // Process asynchronously
            System.enqueueJob(new AccountProcessor(log.Id));

            sendResponse(res, 202, 'Request accepted.', log.Id);

        } catch (Exception e) {

            sendResponse(res, 500, e.getMessage(),null);
        }
    }

    private static void sendResponse(RestResponse res,
                                     Integer code,
                                     String message,
                                     Id logId) {

        res.statusCode = code;

        Map<String, Object> responseMap =
            new Map<String, Object>{
                'message' => message
            };

        if (logId != null) {
            responseMap.put('logId', logId);
        }

        res.responseBody =
            Blob.valueOf(JSON.serialize(responseMap));
    }
}
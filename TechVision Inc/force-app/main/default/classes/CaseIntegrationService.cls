public class CaseIntegrationService implements Queueable, Database.AllowsCallouts {
    private Set<Id> caseIds;

    // Constructor to receive Case IDs from the trigger
    public CaseIntegrationService(Set<Id> ids) {
        this.caseIds = ids;
    }

    public void execute(QueueableContext context) {
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Description 
                            FROM Case WHERE Id IN :caseIds];
        
        for (Case c : cases) {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            // 1. Set Endpoint via Named Credential
            request.setEndpoint('callout:Webhook_Test'); 
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            
            // 2. Prepare Payload (Best practice: Use a Map then Serialize)
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('caseId', c.Id);
            payload.put('caseNumber', c.CaseNumber);
            payload.put('subject', cleanString(c.Subject));
            payload.put('desc', cleanString(c.Description));
            payload.put('status', 'Closed');
            
            request.setBody(JSON.serialize(payload)); 
            
            try {
                HttpResponse response = http.send(request);
                
                // 3. Handle Response (Deserialize Untyped as requested)
                if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    System.debug('Success for Case ' + c.CaseNumber + ': ' + responseBody);
                } else {
                    System.debug('Error Status: ' + response.getStatus());
                }
            } catch (Exception e) {
                System.debug('Callout Failed: ' + e.getMessage());
            }
        }
    }

    /**
     * Cleans strings of &nbsp; and other HTML entities
     */
    private static String cleanString(String input) {
        if (String.isBlank(input)) return '';
        
        // Replace &nbsp; with space, then strip all other &...; entities
        String cleaned = input.replaceAll('(?i)&nbsp;', ' ');
        cleaned = cleaned.replaceAll('&[a-zA-Z0-9#]+;', '');
        
        return cleaned.trim();
    }
}
public class AccountProcessor implements Queueable {

    private Id logId;

    public AccountProcessor(Id logId) {
        this.logId = logId;
    }

    public void execute(QueueableContext context) {

        Integration_Log__c log = [
            SELECT Id, Payload__c
            FROM Integration_Log__c
            WHERE Id = :logId
        ];

        try {

            // 🔹 Clean HTML entities
            String cleanPayload = cleanString(log.Payload__c);

            // 🔹 Parse JSON
            Object raw = JSON.deserializeUntyped(cleanPayload);

            List<Map<String, Object>> records =
                new List<Map<String, Object>>();

            if (raw instanceof List<Object>) {

                for (Object obj : (List<Object>) raw) {
                    records.add((Map<String, Object>) obj);
                }

            } else if (raw instanceof Map<String, Object>) {

                records.add((Map<String, Object>) raw);
            }

            if (records.isEmpty()) {
                updateLog(log, 'Skipped', 'No valid records found.');
                return;
            }

            List<Account> toInsert = new List<Account>();

            for (Map<String, Object> rec : records) {

                toInsert.add(new Account(
                    Name = (String) rec.get('Name'),
                    Phone = (String) rec.get('Phone'),
                    Website = (String) rec.get('Website'),
                    External_ID__c = (String) rec.get('External_ID')
                ));
            }

            // Insert with partial success
            Database.SaveResult[] results =
                Database.insert(toInsert, false);

            Integer successCount = 0;
            String errors = '';

            for (Database.SaveResult sr : results) {

                if (sr.isSuccess()) {
                    successCount++;
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        errors += err.getMessage() + ' | ';
                    }
                }
            }

            if (successCount > 0) {
                updateLog(log,
                          'Processed',
                          'Inserted: ' + successCount);
            } else {
                updateLog(log,
                          'Failed',
                          errors);
            }

        } catch (Exception e) {

            updateLog(log,
                      'Failed',
                      e.getMessage());
        }
    }

    // 🔹 Remove common HTML entities
    private String cleanString(String input) {

        if (String.isBlank(input)) return input;

        return input
            .replace('&nbsp;', ' ')
            .replace('&quot;', '"')
            .replace('&amp;', '&')
            .replace('&lt;', '<')
            .replace('&gt;', '>')
            .trim();
    }

    private void updateLog(Integration_Log__c log,
                           String status,
                           String message) {

        log.Status__c = status;
        log.Error_Message__c = message;
        update log;
    }
}
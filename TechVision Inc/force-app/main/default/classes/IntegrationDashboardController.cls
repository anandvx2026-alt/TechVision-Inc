/**
 * @description Controller for Integration LWC
 * 2026 Best Practice: Use precise exception handling and Security Stripping
 */
public with sharing class IntegrationDashboardController {
    
    @AuraEnabled
    public static void triggerCaseSync(Id caseId) {
        try {
            // Reusing your existing service
            System.enqueueJob(new CaseIntegrationService(new Set<Id>{caseId}));
        } catch (Exception e) {
            throw new AuraHandledException('Sync Failed: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Integration_Log__c> getRecentLogs() {
        // 2026 Standard: Always enforce FLS and CRUD
        return [SELECT Id, Name, Status__c, Error_Message__c, CreatedDate 
                FROM Integration_Log__c 
                WITH USER_MODE 
                ORDER BY CreatedDate DESC 
                LIMIT 10];
    }
}
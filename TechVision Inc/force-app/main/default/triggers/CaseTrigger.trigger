trigger CaseTrigger on Case (after update) {
    Set<Id> closedCaseIds = new Set<Id>();
    
    for (Case c : Trigger.new) {
        Case oldCase = Trigger.oldMap.get(c.Id);
        
        // Only trigger if Status changed to 'Closed'
        if (c.Status == 'Closed' && oldCase.Status != 'Closed') {
            closedCaseIds.add(c.Id);
        }
    }
    
    if (!closedCaseIds.isEmpty()) {
        // Enqueue the job for asynchronous execution
        System.enqueueJob(new CaseIntegrationService(closedCaseIds));
    }
}
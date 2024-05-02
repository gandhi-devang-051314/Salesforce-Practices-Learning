trigger candidateTrigger on Candidate__c (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            candidateTriggerHandler.afterInsert(Trigger.new);
        }
    }
}
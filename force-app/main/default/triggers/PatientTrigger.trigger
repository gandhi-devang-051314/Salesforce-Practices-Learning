trigger PatientTrigger on Patient__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            PatientTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            PatientTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
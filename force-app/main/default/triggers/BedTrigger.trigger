trigger BedTrigger on Bed__c (after update) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            BedTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
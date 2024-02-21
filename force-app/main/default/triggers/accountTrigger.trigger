trigger accountTrigger on Account (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            accountTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            accountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
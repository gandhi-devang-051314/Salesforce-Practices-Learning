trigger UserTrigger on User (after update) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            UserTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
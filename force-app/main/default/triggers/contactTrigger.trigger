trigger contactTrigger on Contact (before insert, before update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            contactTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            contactTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
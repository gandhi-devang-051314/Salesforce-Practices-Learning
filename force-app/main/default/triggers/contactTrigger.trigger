trigger contactTrigger on Contact (before insert, before update, after insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            contactTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            contactTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            contactTriggerHandler.afterInsert(Trigger.new);
        }
    }
}
trigger contactTrigger on Contact (before insert, before update, after insert, after update, after delete) {
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
        when AFTER_UPDATE {
            contactTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE {
            contactTriggerHandler.afterDelete(Trigger.oldMap);
        }
    }
}
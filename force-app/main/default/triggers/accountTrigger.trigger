trigger accountTrigger on Account (after insert, after update, before insert, before delete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            accountTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            accountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        when BEFORE_INSERT {
            accountTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_DELETE {
            accountTriggerHandler.beforeDelete(Trigger.old);
        }
    }
}
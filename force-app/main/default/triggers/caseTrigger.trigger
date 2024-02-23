trigger caseTrigger on Case (before insert, before update, after insert, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            caseTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            caseTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            caseTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            caseTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
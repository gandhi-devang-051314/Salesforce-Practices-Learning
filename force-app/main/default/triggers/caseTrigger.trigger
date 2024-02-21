trigger caseTrigger on Case (before insert, before update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            caseTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            caseTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
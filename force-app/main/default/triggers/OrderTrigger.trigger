trigger OrderTrigger on Order (before update) {
    switch on Trigger.operationType {
        // when AFTER_INSERT {
        //     OrderTriggerHandler.afterInsert(Trigger.new);
        // }
        when BEFORE_UPDATE {
            OrderTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
        // when AFTER_DELETE {
        //     OrderTriggerHandler.afterDelete(Trigger.oldMap);
        // }
        // when AFTER_UNDELETE {
        //     OrderTriggerHandler.afterUndelete(Trigger.new);
        // }
        // when BEFORE_INSERT {
        //     OrderTriggerHandler.beforeInsert(Trigger.new);
        // }
    }
}
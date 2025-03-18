trigger SubscriberTrigger on Subscriber__c (after insert, after delete, after undelete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            SubscriberTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_DELETE {
            SubscriberTriggerHandler.afterDelete(Trigger.oldMap);
        }
        when AFTER_UNDELETE {
            SubscriberTriggerHandler.afterUndelete(Trigger.new);
        }
    }
}
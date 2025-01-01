trigger EventDistributionTrigger on Event_Distribution__c (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            EventDistributionTriggerHandler.beforeUpdate(Trigger.new);
        }
    }
}
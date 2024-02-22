trigger OpportunityTrigger on Opportunity (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            OpportunityTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
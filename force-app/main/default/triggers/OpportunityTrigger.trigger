trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            OpportunityTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE {
            OpportunityTriggerHandler.afterDelete(Trigger.oldMap);
        }
        when AFTER_UNDELETE {
            OpportunityTriggerHandler.afterUndelete(Trigger.new);
        }
    }
}
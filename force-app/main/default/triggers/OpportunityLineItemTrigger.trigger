trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            OpportunityLineItemTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            OpportunityLineItemTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE {
            OpportunityLineItemTriggerHandler.afterDelete(Trigger.oldMap);
        }
        when AFTER_UNDELETE {
            OpportunityLineItemTriggerHandler.afterUndelete(Trigger.new); 
        }
    }
}
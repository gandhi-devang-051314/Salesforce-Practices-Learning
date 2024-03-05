trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            OpportunityContactRoleTriggerHandler.beforeInsert(Trigger.new);
        }
    }
}
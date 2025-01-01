public class EventDistributionTriggerHandler {

    public static void beforeUpdate(List<Event_Distribution__c> newEventDistributions) {
        // controllEventCapacityFromDistributions(newEventDistributions);
    }

    //logic-functions-----------------------------------------------------------------------------------------------------

    //problem #57
    private static void controllEventCapacityFromDistributions(List<Event_Distribution__c> newEventDistributions) {
        Set<Id> eventIds = new Set<Id>();

        for (Event_Distribution__c ed : newEventDistributions) {
            if (ed.Event__c != null && ed.Distribution__c != null && ed.Distribution__c != 0) {
                eventIds.add(ed.Event__c);
            }
        }

        if (eventIds.size() > 0) {
            Map<Id, Event__c> eventInfoMap = new Map<Id, Event__c>([SELECT Id, Event_Capacity__c FROM Event__c WHERE Id IN :eventIds]);
            List<SObject> recordNeedsUpdate = new List<SObject>();

            for (Event_Distribution__c ed : newEventDistributions) {
                if (eventInfoMap.containsKey(ed.Event__c)) {
                    Decimal count = eventInfoMap.get(ed.Event__c).Event_Capacity__c - ed.Distribution__c;

                    if (count >= 0) {
                        Event__c e = eventInfoMap.get(ed.Event__c);
                        e.Event_Capacity__c = count;
                        recordNeedsUpdate.add(e);
                    }
                    else {
                        ed.Status__c = 'Waiting';
                    }
                }
            }

            if (recordNeedsUpdate.size() > 0) {
                update recordNeedsUpdate;
            }
        }
    }
}

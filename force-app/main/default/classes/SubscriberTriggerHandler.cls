public class SubscriberTriggerHandler {

    public static void afterInsert(List<Subscriber__c> newSub) {
        // identifyMostRecentSubscriber(newSub, null);
    }

    public static void afterDelete(Map<Id, Subscriber__c> oldSubMap) {
        // identifyMostRecentSubscriber(null, oldSubMap);
    }

    public static void afterUndelete(List<Subscriber__c> newSub) {
        // identifyMostRecentSubscriber(newSub, null);
    }


    //Trigger #60
    private static void identifyMostRecentSubscriber(List<Subscriber__c> newSub, Map<Id, Subscriber__c> oldSubMap) {
        Set<Id> accIds = new Set<Id>();

        if (newSub == null) { //delete case
            for (Subscriber__c s : oldSubMap.values()) {
                if (s.Account__c != null) {
                    accIds.add(s.Account__c);
                }
            }
        }
        else {
            for (Subscriber__c s : newSub) {
                if (s.Account__c != null) {
                    accIds.add(s.Account__c);
                }
            }
        }

        if (!accIds.isEmpty()) {
            List<Subscriber__c> subList = [SELECT Id, Account__c, Recent_Subscriber__c FROM Subscriber__c WHERE Account__c IN :accIds ORDER BY CreatedDate DESC];
            accIds.clear();

            for (Subscriber__c s : subList) {
                if (!accIds.contains(s.Account__c)) {
                    s.Recent_Subscriber__c = true;
                    accIds.add(s.Account__c);
                }
                else {
                    s.Recent_Subscriber__c = false;
                }
            }

            update subList;
        }
    }
}
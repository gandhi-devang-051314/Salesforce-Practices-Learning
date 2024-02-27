public class accountTriggerHandler {

    public static void afterInsert(List<Account> newAccs) {
        // createRelatedContact(newAccs, null);
        //closeOpps(newAccs, null);
    }

    public static void afterUpdate(List<Account> newAccs, Map<Id, Account> oldAccs) {
        // createRelatedContact(newAccs, oldAccs);
        //closeOpps(newAccs, oldAccs);
    }

    //logic-functions

    //problem #3
    private static void createRelatedContact(List<Account> newAccs, Map<Id, Account> oldAccs){
        List<Contact> conList = new List<Contact>();
        for (Account ac : newAccs) {
            if(
                (oldAccs == null && ac.Create_Contact__c == true) ||
                (oldAccs != null && oldAccs.get(ac.Id).Create_Contact__c == false && ac.Create_Contact__c == true)
            ){
                Contact c = new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact',
                    AccountId = ac.Id
                );
                conList.add(c);
            }
        }

        if(!conList.isEmpty()){
            insert conList;
        }
    }

    //problem #11
    private static void closeOpps(List<Account> newAccs, Map<Id, Account> oldAccs){
        Set<Id> accIds = new Set<Id>();

        for (Account ac : newAccs) {
            if(
                (oldAccs == null && ac.Close_Opportunities__c == true) ||
                (oldAccs != null && oldAccs.get(ac.Id).Close_Opportunities__c != ac.Close_Opportunities__c && ac.Close_Opportunities__c == true)
            ){
                accIds.add(ac.Id);
            }
        }

        if(accIds != null && accIds.size() > 0){
            List<Opportunity> oppList = [SELECT Id, StageName, AccountId, CloseDate FROM Opportunity WHERE Probability > 70 AND AccountId IN :accIds AND StageName != 'Closed Won'];

            if(oppList != null && oppList.size() > 0){
                for (Opportunity opp : oppList) {
                    opp.StageName = 'Closed Won';
                    opp.CloseDate = Date.today();
                }

                try {
                    update oppList;
                } catch (Exception e) {
                    System.debug('Exception handled'+e);
                }
            }
        }
    }
}
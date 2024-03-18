public class accountTriggerHandler {

    public static void afterInsert(List<Account> newAccs) {
        // createRelatedContact(newAccs, null);
        //closeOpps(newAccs, null);
        // deleteOpportunitesDoNotContactInactiveAccount(newAccs, null);
        // createRelatedContactAndClientContact(newAccs);
    }

    public static void afterUpdate(List<Account> newAccs, Map<Id, Account> oldAccs) {
        // createRelatedContact(newAccs, oldAccs);
        //closeOpps(newAccs, oldAccs);
        // deleteOpportunitesDoNotContactInactiveAccount(newAccs, oldAccs);
        // closeLostAllOpportunites(newAccs, oldAccs);
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

    //problem #18
    private static void deleteOpportunitesDoNotContactInactiveAccount(List<Account> newAccs, Map<Id, Account> oldAccs){
        Set<Id> accIds = new Set<Id>();

        for (Account ac : newAccs) {
            if(
                (oldAccs == null && !ac.Active__c) ||
                (oldAccs != null && oldAccs.get(ac.Id).Active__c != ac.Active__c && !ac.Active__c)
            ){
                accIds.add(ac.Id);
            }
        }

        if(accIds != null && accIds.size() > 0){
            List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE AccountId IN :accIds];
            List<Contact> conList = [SELECT Id, Primary_Contact__c FROM Contact WHERE AccountId IN :accIds];

            if(conList != null && conList.size() > 0){
                for (Contact con : conList) {
                    con.Primary_Contact__c = false;
                }

                try {
                    update conList;
                } catch (Exception e) {
                    System.debug('DML Error Contact updation!'+e);
                }
            }

            if(oppList != null && oppList.size() > 0){
                try {
                    delete oppList;
                } catch (Exception e) {
                    System.debug('DML Error delete Opportunites!'+e);
                }
            }
        }
    }

    //problem #23
    private static void createRelatedContactAndClientContact(List<Account> newAccs){
        List<Contact> conList = new List<Contact>();

        for (Account ac : newAccs) {
            Contact c = new Contact(
                FirstName = 'Test Client',
                LastName = 'Lookup Test',
                AccountId = ac.Id
            );
            conList.add(c);
        }

        if(conList != null && conList.size() > 0){
            try {
                insert conList;
            } catch (Exception e) {
                System.debug('DML Exception on insertion of Contacts'+e);
            }

            List<Account> accUpdateList = new List<Account>();

            for (Contact c : conList) {
                Account ac = new Account(
                    Id = c.AccountId,
                    Client_Contact__c = c.Id
                );
                accUpdateList.add(ac);
            }

            if (accUpdateList != null && accUpdateList.size() > 0) {
                try {
                    update accUpdateList;
                } catch (Exception e) {
                    System.debug('DML Exception on update Accounts with Client Contact'+e);
                }
            }
        }   
    }

    //problem #27
    private static void closeLostAllOpportunites(List<Account> newAccs, Map<Id, Account> oldAccs){
        Set<Id> accIds = new Set<Id>();

        for (Account ac : newAccs) {
            accIds.add(ac.Id);
        }

        if(accIds != null && accIds.size() > 0){
            List<Opportunity> oppList = [SELECT Id, CloseDate, StageName, CreatedDate FROM Opportunity WHERE AccountId IN :accIds];
            List<Opportunity> updatedOppList = new List<Opportunity>();

            if(oppList != null && oppList.size() > 0){
                for (Opportunity op : oppList) {
                    Integer diffOfDays = op.CreatedDate.Date().daysBetween(Date.today());

                    if(diffOfDays > 30 && op.StageName != 'Closed Won'){
                        op.StageName = 'Closed Lost';
                        op.CloseDate = Date.today();
                        updatedOppList.add(op);
                    }
                }
            }

            if(updatedOppList != null && updatedOppList.size() > 0){
                try {
                    update updatedOppList;
                } catch (Exception e) {
                    System.debug('Exception in DML'+e);
                }
            }
        }
    }
}
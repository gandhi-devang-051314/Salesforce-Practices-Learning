public with sharing class contactTriggerHandler {

    public static void beforeInsert(List<Contact> newContacts){
        // primaryContact(newContacts);
    }

    public static void beforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        // primaryContact(newContacts);
    }

    public static void afterInsert(List<Contact> newContacts) {
        
    }

    public static void afterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        
    }


    //--------------------------------------------------logic functions-----------------------------------------------------------

    //One Account can not have multiple contacts select as primary contacts
    //Problem #1
    private static void primaryContact(List<Contact> newContacts){
        Set<Id> Ids = new Set<Id>();
        for (Contact c : newContacts) {
            if(c.Primary_Contact__c == true){
                Ids.add(c.AccountId);
            }
        }

        if(Ids!= null && Ids.size() > 0){
            Map<Id, Account> getAccounts = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Primary_Contact__c = true AND AccountId IN :Ids)]);

            if(getAccounts != null){
                for(Contact c : newContacts){
                    if(getAccounts.keySet().contains(c.AccountId)){
                       c.addError('Primary Contact Error!');
                    }
                }
            }
        }
    }


}
public class accountTriggerHandler {

    public static void beforeInsert(List<Account> newAccs) {
        // preventDuplicateAccountOnName(newAccs);
    }

    public static void afterInsert(List<Account> newAccs) {
        // createRelatedContact(newAccs, null);
        //closeOpps(newAccs, null);
        // deleteOpportunitesDoNotContactInactiveAccount(newAccs, null);
        // createRelatedContactAndClientContact(newAccs);
        // insertNumberOfContactsBasedOnValue(newAccs);
    }

    public static void afterUpdate(List<Account> newAccs, Map<Id, Account> oldAccs) {
        // createRelatedContact(newAccs, oldAccs);
        //closeOpps(newAccs, oldAccs);
        // deleteOpportunitesDoNotContactInactiveAccount(newAccs, oldAccs);
        // closeLostAllOpportunites(newAccs, oldAccs);
        // changeOwnerToRelatedConsAndOpps(newAccs, oldAccs);
        // sendEmailToOwnerAboutModifiedContactsBetweenAccountLastUpdateAndCurrentUpdate(newAccs, oldAccs);
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

    //problem #31
    private static void preventDuplicateAccountOnName(List<Account> newAccs){
        Set<String> accNames = new Set<String>();

        for (Account ac : newAccs) {
            if (ac.Name != null) {
                accNames.add(ac.Name);
            }
        }

        if (accNames != null && accNames.size() > 0) {
            List<Account> accList = [SELECT Id, Name FROM Account WHERE Name IN :accNames];
            Map<String, Account> nameToAccount = new Map<String, Account>();

            if (accList != null && accList.size() > 0) {
                for (Account a : accList) {
                    nameToAccount.put(a.Name, a);   
                }
            }

            if(nameToAccount != null && nameToAccount.size() > 0){
                for (Account a : newAccs) {
                    if(nameToAccount.containsKey(a.Name)){
                        a.addError('Duplicate Name Found!');
                    }
                }
            }
        }
    }

    //problem #33
    private static void changeOwnerToRelatedConsAndOpps(List<Account> newAccs, Map<Id, Account> oldAccs) {
        Map<Id, Id> accIdsToOwnerIds = new Map<Id, Id>();

        for (Account ac : newAccs) {
            if (oldAccs != null && oldAccs.get(ac.Id).OwnerId != ac.OwnerId && ac.OwnerId != null) {
                accIdsToOwnerIds.put(ac.Id, ac.OwnerId);
            }
        }

        if (accIdsToOwnerIds != null && accIdsToOwnerIds.size() > 0) {
            List<Contact> conList = [SELECT Id, AccountId, OwnerId FROM Contact WHERE AccountId IN :accIdsToOwnerIds.keySet()];
            List<Opportunity> oppList = [SELECT Id, AccountId, OwnerId FROM Opportunity WHERE AccountId IN :accIdsToOwnerIds.keySet()];
            List<sObject> updatedRecords = new List<sObject>();

            if (conList != null && conList.size() > 0) {
                for (Contact c : conList) {
                    c.OwnerId = accIdsToOwnerIds.get(c.AccountId);
                    updatedRecords.add(c);
                }
            }

            if (oppList != null && oppList.size() > 0) {
                for (Opportunity o : oppList) {
                    o.OwnerId = accIdsToOwnerIds.get(o.AccountId);
                    updatedRecords.add(o);
                }
            }

            if (updatedRecords != null && updatedRecords.size() > 0) {
                try {
                    update updatedRecords;
                } catch (Exception e) {
                    System.debug('Exception on update DML'+e);
                }
            }
        }
    }

    //problem #37
    private static void insertNumberOfContactsBasedOnValue(List<Account> newAccs) {
        Map<Id, Decimal> accIdToNumberOfContacts = new Map<Id, Decimal>();

        for (Account ac : newAccs) {
            if(ac.Number_Of_Contacts__c > 10) {
                ac.addError('Maximum 10 contacts can be entered on account while insertion!');
            }
            else if (ac.Number_Of_Contacts__c != null && ac.Number_Of_Contacts__c != 0) {
                accIdToNumberOfContacts.put(ac.Id, ac.Number_Of_Contacts__c);
            }
        }

        if (accIdToNumberOfContacts.size() > 0) {
            List<Contact> conList = new List<Contact>();

            for (Id acId : accIdToNumberOfContacts.keySet()) {
                for (Integer i = 0; i < accIdToNumberOfContacts.get(acId); i++) {
                    conList.add(
                        new Contact(
                            FirstName = 'Test',
                            LastName = 'Contact'+i,
                            AccountId = acId
                        )
                    );
                }
            }

            if (conList.size() > 0) {
                try {
                    insert conList;
                } catch (Exception e) {
                    System.debug('insert DML Error'+e);
                }
            }
        }
    }

    //problem #39
    private static void sendEmailToOwnerAboutModifiedContactsBetweenAccountLastUpdateAndCurrentUpdate(List<Account> newAccs, Map<Id, Account> oldAccs) {
        Map<Id, List<DateTime>> accIdToUpdateDates = new Map<Id, List<DateTime>>();

        for (Account ac : newAccs) {
            if (ac.OwnerId != null) {
                List<DateTime> dtList = new List<DateTime>();
                dtList.add(oldAccs.get(ac.Id).LastModifiedDate);
                dtList.add(ac.LastModifiedDate);
                accIdToUpdateDates.put(ac.Id, dtList);
            }
        }

        if (accIdToUpdateDates.size() > 0) {
            List<Contact> conList = [SELECT Id, Name,  AccountId, Account.Name, Account.Owner.Email, LastModifiedDate FROM Contact WHERE AccountId IN :accIdToUpdateDates.keySet()];

            if (conList.size() > 0) {
                List<Messaging.SingleEmailMessage> emailNeedstoSendList = new List<Messaging.SingleEmailMessage>();
                Map<String, String> emailToBodyMap = new Map<String, String>();
                for (Contact con : conList) {
                    List<DateTime> dtList = accIdToUpdateDates.get(con.AccountId);
                    if (dtList[0] < con.LastModifiedDate && dtList[1] > con.LastModifiedDate) {
                        if (emailToBodyMap.containsKey(con.Account.Owner.Email)) {
                            String detail = emailToBodyMap.get(con.Account.Owner.Email);
                            detail = detail+'\n'+'AccountName: '+con.Account.Name+'\t'+'ContactName: '+con.Name;
                            emailToBodyMap.put(con.Account.Owner.Email, detail);
                        }
                        else{
                            emailToBodyMap.put(con.Account.Owner.Email, 'AccountName: '+con.Account.Name+'\t'+'ContactName: '+con.Name);
                        }
                    }
                }

                if (emailToBodyMap.size() > 0) {
                    for (String e : emailToBodyMap.keySet()) {
                        Messaging.SingleEmailMessage ms = new Messaging.SingleEmailMessage();
                        ms.setToAddresses(new List<String>{e});
                        ms.setPlainTextBody(emailToBodyMap.get(e));
                        ms.setSubject('About Contact Details those were updated from last Account Update');
                        emailNeedstoSendList.add(ms);
                    }
                }

                if (emailNeedstoSendList.size() > 0) {
                    try {
                        Messaging.sendEmail(emailNeedstoSendList);
                    } catch (Exception e) {
                        System.debug('Error while sending mails'+e);
                    }
                }
            }
        }
    }
}
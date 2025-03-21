public with sharing class contactTriggerHandler {

    public static void beforeInsert(List<Contact> newContacts){
        // primaryContact(newContacts);
        // preventDuplicates(newContacts, null);
        // errorOnThirdContactOnAccount(newContacts);
    }

    public static void beforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        // primaryContact(newContacts);
        // preventDuplicates(newContacts, oldContacts);
    }

    public static void afterInsert(List<Contact> newContacts) {
        // createUserAndAssignPublicGroup(newContacts);
        // updateAccountDescifOppFoundOrCreateNewOpp(newContacts);
        // checkedNewContactAndUnchekecOnOldContacts(newContacts);
        // updateAccountDescriptionWithContactInfo(newContacts, null);
        // createCaseOnAccount(newContacts);
    }

    public static void afterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        // updateAccountDescriptionWithContactInfo(newContacts, oldContacts);
        // updatePhoneOnAccountAndAllRelatedContacts(newContacts, oldContacts);
        // createCaseOnAccount(newContacts);
    }

    public static void afterDelete(Map<Id, Contact> oldContacts) {
        // updateAccountDescriptionWithContactInfo(null, oldContacts);
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

    //problem #19 (contact is non-setup obj and user / groupMember is setup object so getting mixed DML error to remove this we use future method)
    private static void createUserAndAssignPublicGroup(List<Contact> newContacts){
        Set<Id> conIds = new Set<Id>();

        for (Contact c : newContacts) {
            conIds.add(c.Id);
        }

        avoidMixedDML(conIds);
    }

    @future
    private static void avoidMixedDML(Set<Id> conIds){
        if(conIds != null && conIds.size() > 0){
            List<Contact> conList = [SELECT Id, LastName, Email FROM Contact WHERE Id IN :conIds];
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
            Group salesTeam = [SELECT Id FROM Group WHERE Name = 'Sales Team' LIMIT 1];
            UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Western Sales Team' LIMIT 1];

            List<User> userList = new List<User>();

            for (Contact c : conList) {
                if(c.Email != null){
                    User u = new User(
                        LastName = c.LastName,
                        Email = c.Email,
                        UserName = c.Email,
                        UserRoleId = role.Id,
                        Alias = 'sales',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',
                        ProfileId = p.Id,
                        ContactId = c.Id,
                        LanguageLocaleKey = 'en_US',
                        EmailEncodingKey = 'UTF-8'
                    );
                    userList.add(u);
                }
            }

            if(salesTeam != null && userList != null && userList.size() > 0){
                try {
                    insert userList;
                } catch (Exception e) {
                    System.debug('DML Exception while insertion of users'+e);
                }
    
                List<GroupMember> assignUserToGroupList = new List<GroupMember>();
                for (User u : userList) {
                    GroupMember gm = new GroupMember(
                        UserOrGroupId = u.Id,
                        GroupId = salesTeam.Id
                    );
                    assignUserToGroupList.add(gm);
                }
    
                if(assignUserToGroupList != null && assignUserToGroupList.size() > 0){
                    try {
                        insert assignUserToGroupList;
                    } catch (Exception e) {
                        System.debug('DML Exception while insertion of groupMembers assignment'+e);
                    }
                }
            }
        }
    }

    //problem #24
    private static void preventDuplicates(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        Set<String> emails = new Set<String>();
        Set<String> phones = new Set<String>();

        for (Contact c : newContacts) {
            if(
                (c.Email != null && oldContacts == null) ||
                (oldContacts != null && c.Email != null && oldContacts.get(c.Id).Email != c.Email)
            ){
                emails.add(c.Email);
            }

            if(
                (c.Phone != null && oldContacts != null) ||
                (oldContacts != null && c.Phone != null && oldContacts.get(c.Id).Phone != c.Phone)
            ){
                phones.add(c.Phone);
            }
        }

        if (
            (emails != null && emails.size() > 0) ||
            (phones != null && phones.size() > 0)
        ) {
            List<Contact> conList = [SELECT Id, Phone, Email FROM Contact WHERE Phone IN :phones OR Email IN :emails];

            if (conList != null && conList.size() > 0) {
                Set<String> duplicateEmails = new Set<String>();
                Set<String> duplicatePhones = new Set<String>();

                for (Contact c : conList) {
                    if(c.Email != null){
                        duplicateEmails.add(c.Email);
                    }

                    if(c.Phone != null){
                        duplicatePhones.add(c.Phone);
                    }
                }

                for (Contact c : newContacts) {
                    if(duplicateEmails.contains(c.Email)){
                        c.addError('Duplicate Email Found on Contact!');
                    }

                    if(duplicatePhones.contains(c.Phone)){
                        c.addError('Duplicate Phone found on Contact!');
                    }
                }
            }
        }
    }

    //problem #26
    private static void errorOnThirdContactOnAccount(List<Contact> newContacts){
        Set<Id> accIds = new Set<Id>();

        for (Contact c : newContacts) {
            if(c.AccountId != null){
                accIds.add(c.AccountId);
            }
        }

        if(accIds != null && accIds.size() > 0){
            Map<Id ,Account> accMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE Id IN :accIds]);

            if (accMap != null && accMap.values().size() > 0) {
                for (Contact c : newContacts) {
                    if(accMap.containsKey(c.AccountId) && accMap.get(c.AccountId).Contacts.size() > 2){
                        c.addError('There are already two contacts on parent account!');
                    }
                }
            }
        }
    }

    //problem #32
    private static void updateDescriptionOnAccountDescription(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        Set<Id> accIds = new Set<Id>();

        for (Contact c : newContacts) {
            if (
                (oldContacts == null && c.AccountId != null && c.Description != null) ||
                (oldContacts != null && c.AccountId != null && oldContacts.get(c.Id).Description != c.Description && c.Description != null)
            ) {
                accIds.add(c.AccountId);
            }
        }

        if (accIds != null && accIds.size() > 0) {
            List<Contact> conList = [SELECT Id, AccountId, Description FROM Contact WHERE AccountId IN :accIds];
            List<Account> accList = new List<Account>();

            if (conList != null && conList.size() > 0) {
                for (Contact c : conList) {
                    Account a = new Account(
                        Id = c.AccountId,
                        Description = c.Description
                    );
                    accList.add(a);
                }
            }

            if(accList != null && accList.size() > 0) {
                try {
                    update accList;
                } catch (Exception e) {
                    System.debug('DML Exception'+e);
                }
            }
        }
    }

     //problem #33
     private static void enforceSinglePrimaryContactOnAccount(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> accIds = new Set<Id>();

        for (Contact c : newContacts) {
            if (
                (oldContacts == null && c.AccountId != null && c.Primary_Contact__c == true) ||
                (oldContacts != null && c.AccountId != null && oldContacts.get(c.Id).Primary_Contact__c != c.Primary_Contact__c && c.Primary_Contact__c == true)
            ){
                accIds.add(c.AccountId);
            }
        }

        if (accIds != null && accIds.size() > 0) {
            Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Primary_Contact__c = true) FROM Account WHERE Id IN :accIds]);

            if(accMap != null && accMap.size() > 0){
                for (Contact c : newContacts) {
                    if (accMap.containsKey(c.AccountId) && accMap.get(c.AccountId).Contacts.size() > 0){
                        c.addError('Duplicate Primary Contact on Account!');
                    }
                }
            }
        }
    }

    //problem #34
    private static void enforceAtleastOnePrimaryContact(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> accIds = new Set<Id>();

        for (Contact c : newContacts) {
            if (
                (oldContacts == null && c.AccountId != null && !c.Primary_Contact__c) ||
                (oldContacts != null && c.AccountId != null && oldContacts.get(c.Id).Primary_Contact__c != c.Primary_Contact__c && !c.Primary_Contact__c)
            ){
                accIds.add(c.AccountId);
            }
        }

        if (accIds != null && accIds.size() > 0) {
            Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Primary_Contact__c = true) FROM Account WHERE Id IN :accIds]);
            
            if (accMap != null && accMap.size() > 0) {
                for (Contact c : newContacts) {
                    if ( 
                        (accMap.containsKey(c.AccountId) && Trigger.isUpdate && accMap.get(c.AccountId).Contacts.size() < 2) ||
                        (accMap.containsKey(c.AccountId) && Trigger.isInsert && accMap.get(c.AccountId).Contacts.size() < 1)
                    ) {
                        c.addError('You need atleast one Contact as Primary Contact on Account!');
                    }
                }
            }
        }
    }

    //problem #36
    private static void updateAccountDescifOppFoundOrCreateNewOpp(List<Contact> newContacts) {
        Set<Id> accIds = new Set<Id>();
        for (Contact c : newContacts) {
            if (c.AccountId != null) {
                accIds.add(c.AccountId);
            }
        }

        if (accIds.size() > 0) {
            List<Account> accList = [SELECT Id, Description, (SELECT Id, Amount FROM Opportunities) FROM Account WHERE Id IN :accIds];
            List<Account> accUpdateList = new List<Account>();
            List<Opportunity> newOppList = new List<Opportunity>();

            if (accList.size() > 0) {
                for (Account a : accList) {
                    Decimal amount = 0;
                    if (a.Opportunities.size() > 0) {
                        for (Opportunity o : a.Opportunities) {
                            amount += o.Amount;
                        }
                        accUpdateList.add(new Account(Id = a.Id, Description = String.valueOf(amount)));
                    }
                    else {
                        Opportunity o = new Opportunity(
                            Name = 'Test Amount Opp',
                            Amount = 1234,
                            AccountId = a.Id,
                            StageName = 'Closed Won',
                            CloseDate = Date.valueOf('2024-10-10')
                        );
                        newOppList.add(o);
                    }
                }
            }

            if (accUpdateList.size() > 0) {
                try {
                    update accUpdateList;
                } catch (Exception e) {
                    System.debug('DML on acc update'+e);
                }
            }

            if (newOppList.size() > 0) {
                try {
                    insert newOppList;
                } catch (Exception e) {
                    System.debug('DML on oppo insert'+e);
                }
            }
        }
    }

    //problem #44
    private static void checkedNewContactAndUnchekecOnOldContacts(List<Contact> newContacts) {
        Set<Id> accIds = new Set<Id>();

        for (Contact c : newContacts) {
            if (c.AccountId != null) {
                accIds.add(c.AccountId);
            }
        }

        if (accIds.size() > 0) {
            List<Contact> conList = [SELECT Id, New_Contact__c, AccountId FROM Contact WHERE AccountId IN :accIds ORDER BY CreatedDate DESC];
            Set<Id> accIdsHavingLatestContact = new Set<Id>();
            List<Contact> conListNeedsUpdate = new List<Contact>();

            if (conList.size() > 0) {
                for (Contact c : conList) {
                    if (!accIdsHavingLatestContact.contains(c.AccountId)) {
                        accIdsHavingLatestContact.add(c.AccountId);
                        c.New_Contact__c = true;
                        conListNeedsUpdate.add(c);
                    }
                    else{
                        c.New_Contact__c = false;
                        conListNeedsUpdate.add(c);
                    }
                }
            }

            if (conListNeedsUpdate.size() > 0) {
                try {
                    update conListNeedsUpdate;
                } catch (Exception e) {
                    System.debug('Exception occuring on updation'+e);
                }
            }
        }
    }

    //problem #46
    private static void updateAccountDescriptionWithContactInfo(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> accIds = new Set<Id>();
        
        if (newContacts != null) {
            for (Contact c : newContacts) {
                if (c.AccountId != null) {
                    accIds.add(c.AccountId);
                }
                if (oldContacts.get(c.Id).AccountId != null && c.AccountId != oldContacts.get(c.Id).AccountId) { // for the update we need to remove contact from old Parent Account and add to new Parent Account
                    accIds.add(oldContacts.get(c.Id).AccountId);
                }
            }
        }
        else if (newContacts == null) { //delete case
            for (Contact c : oldContacts.values()) {
                if (c.AccountId != null) {
                    accIds.add(c.AccountId);
                }
            }
        }

        if (accIds.size() > 0) {
            List<Contact> conList = [SELECT Name, CreatedDate, AccountId FROM Contact WHERE AccountId IN :accIds];
            Map<Id, Account> updateAccMap = new Map<Id, Account>();

            for (Contact c : conList) {
                if (updateAccMap.containsKey(c.AccountId)) {
                    Account a = updateAccMap.get(c.AccountId);

                    List<Object> ca = (List<Object>)JSON.deserializeUntyped(a.Description);
                    Map<String, Object> m = new Map<String, Object>();
                    m.put('contactName', c.Name);
                    m.put('createdDate', c.CreatedDate);
                    ca.add(m);

                    a.Description = JSON.serialize(ca);
                    updateAccMap.put(c.AccountId, a);
                }
                else {
                    Account a = new Account(Id = c.AccountId);

                    List<Object> ca = new List<Object>();
                    Map<String, Object> m = new Map<String, Object>();
                    m.put('contactName', c.Name);
                    m.put('createdDate', c.CreatedDate);
                    ca.add(m);

                    a.Description = JSON.serialize(ca);
                    updateAccMap.put(c.AccountId, a);
                }
            }

            if (updateAccMap.size() > 0) {
                try {
                    update updateAccMap.values();
                } catch (Exception e) {
                    System.debug('DML Exception while updating Accounts ==> '+e.getMessage());
                }
            }
        }
    }

    //problem #48
    private static void updatePhoneOnAccountAndAllRelatedContacts(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Map<Id, String> phoneToIdMap = new Map<Id, String>();

        for (Contact c : newContacts) {
            if (c.Phone != null && c.Phone != oldContacts.get(c.Id).Phone && c.AccountId != null) {
                phoneToIdMap.put(c.AccountId, c.Phone);
            }
        }

        if (phoneToIdMap.size() > 0) {
            List<Contact> conList = [SELECT Id, AccountId, Phone FROM Contact WHERE AccountId IN :phoneToIdMap.keySet()];
            List<SObject> updateList = new List<SObject>();
            Map<Id, Account> accMap = new Map<Id, Account>(); //we take map because if we directly insert acc in above list it gives duplicate Ids found error!

            for (Contact c : conList) {
                c.Phone = phoneToIdMap.get(c.AccountId);
                updateList.add(c);

                accMap.put(
                    c.AccountId, 
                    new Account(
                        Id = c.AccountId,
                        Phone = phoneToIdMap.get(c.AccountId)
                    )
                );
            }

            if (accMap.size() > 0) {
                updateList.addAll(accMap.values());
            }

            if (updateList.size() > 0) {
                try {
                    update updateList;
                } catch (Exception e) {
                    System.debug('Exception occured in updating list --> '+e.getMessage());
                }
            }
        }
    }

    //problem #54
    private static void createCaseOnAccount(List<Contact> newContacts) {
        Set<Id> accIds = new Set<Id>();

        for (Contact c : newContacts) {
            if (c.AccountId != null) {
                accIds.add(c.AccountId);
            }
        }

        if (accIds.size() > 0) {
            Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN :accIds AND Type = 'Premium']);
            List<Case> caseList = new List<Case>();

            for (Contact c : newContacts) {
                if (accMap.containsKey(c.AccountId)) {
                    caseList.add(
                        new Case(
                            Subject = 'New Case on Contact',
                            Description = 'Contact FirstName ==> '+c.FirstName+', Contact LastName ==> '+c.LastName,
                            AccountId = c.AccountId,
                            OwnerId = accMap.get(c.AccountId).OwnerId
                        )
                    );
                }
            }

            if (caseList.size() > 0) {
                insert caseList;
            }
        }
    }
}
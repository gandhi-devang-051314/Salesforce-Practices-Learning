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
}
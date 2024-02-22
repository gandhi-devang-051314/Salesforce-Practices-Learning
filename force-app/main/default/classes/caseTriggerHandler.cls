public class caseTriggerHandler {

    public static void beforeInsert(List<Case> newCases){
        // suppliedEmail(newCases, null);
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldCases){
        // suppliedEmail(newCases, oldCases);
    }

    //problem statements
    //Problem #2
    private static void suppliedEmail(List<Case> newCases, Map<Id, Case> oldCases){
        Set<String> caseEmails = new Set<String>();

        for(Case c : newCases){
            if(
                (oldCases == null && c.Supplied_Email__c != null) ||
                (oldCases == null && c.Supplied_Email__c != null && oldCases.get(c.Id).Supplied_Email__c != c.Supplied_Email__c)
            ){
                caseEmails.add(c.Supplied_Email__c);
            }
        }

        List<Contact> contactRecordMap = [SELECT Id, Email FROM Contact WHERE Email IN :caseEmails];
        Map<String, Id> contactEmailToIdMap = new Map<String, Id>();

        for(Contact c : contactRecordMap){
            contactEmailToIdMap.put(c.Email, c.Id);
        }

        List<Contact> conList = new List<Contact>();
        Map<String, Id> conEmailToIdMap = new Map<String, Id>();

        for(Case c :newCases){
            if(contactEmailToIdMap.containsKey(c.Supplied_Email__c) && c.Supplied_Email__c != null){
                c.ContactId = contactEmailToIdMap.get(c.Supplied_Email__c);
            }
            else{
                Contact con = new Contact(
                    LastName = 'Test Contact',
                    Email = c.Supplied_Email__c
                );
                conList.add(con);
            }
        }

        if(!conList.isEmpty()){
            try {
                insert conList;
            } catch (Exception e) {
                System.debug('Exception occured!'+e);
            }
        }

        for(Contact c : conList){
            conEmailToIdMap.put(c.Email, c.Id);
        }

        for (Case c : newCases) {
            if(c.Supplied_Email__c != null && conEmailToIdMap.containsKey(c.Supplied_Email__c)){
                c.ContactId = conEmailToIdMap.get(c.Supplied_Email__c);
            }
        }
    }

    //problem #4
    private static void followupTaskOnPrimaryContact(List<Case> newCases, Map<Id, Case> oldCases){
        Set<Id> accIds = new Set<Id>();

        for (Case c : newCases) {
            if(
                (oldCases == null && newCases.Create_Task__c == true) ||
                (oldCases != null && oldCases.get(c.Id).Create_Task__c == false && newCases.Create_Task__c == true)
            ){
                accIds.add(c.AccountId);
            }
        }

        List<Contact> conList = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accIds AND Primary_Contact__c = true];

        if(!conList.isEmpty()){
            List<Task> taskList = new List<Task>();
            for (Contact con : conList) {
                Task t = new Task(
                    Subject = 'Followup Task',
                    Status = 'In Progress',
                    WhoId = con.Id,
                    WhatId = con.AccountId
                );
                taskList.add(t);
            }

            if(!taskList.isEmpty()){
                insert taskList;
            }
        }
    }
}
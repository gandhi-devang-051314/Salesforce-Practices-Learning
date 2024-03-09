public class caseTriggerHandler {

    public static void beforeInsert(List<Case> newCases){
        // suppliedEmail(newCases, null);
        // linkCaseToPrimaryContactAndCreateEventWithSameSubject(newCases, null);
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldCases){
        // suppliedEmail(newCases, oldCases);
    }

    public static void afterInsert(List<Case> newCases){
        // followupTaskOnPrimaryContact(newCases, null);
        //updateAccountRatingBasedOnClosedCases(newCases, null);
        //countCaseStatusOnAccount(newCases, null);
    }

    public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldCases){
        // followupTaskOnPrimaryContact(newCases, oldCases);
        //updateAccountRatingBasedOnClosedCases(newCases, oldCases);
        //countCaseStatusOnAccount(newCases, null);
        // updateAccountDescriptionAndTaskStatus(newCases, oldCases);
    }

    public static void afterDelete(Map<Id, Case> oldCases){
        //countCaseStatusOnAccount(null, oldCases);
    }

    public static void afterUndelete(List<Case> newCases){
        //countCaseStatusOnAccount(newCases, null);
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

    //problem #5
    private static void followupTaskOnPrimaryContact(List<Case> newCases, Map<Id, Case> oldCases){
        Set<Id> accIds = new Set<Id>();

        // for (Case c : newCases) {
        //     if(
        //         //(oldCases == null && newCases.Create_Task__c == true) ||
        //         //(oldCases != null && oldCases.get(c.Id).Create_Task__c == false && newCases.Create_Task__c == true)
        //     ){
        //         accIds.add(c.AccountId);
        //     }
        // }

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

    //problem #7
    private static void updateAccountRatingBasedOnClosedCases(List<Case> newCases, Map<Id, Case> oldCases){
        Set<Id> accIds = new Set<Id>();

        for (Case ca : newCases) {
            if(
                (oldCases == null && ca.Status == 'Working') ||
                (oldCases != null && oldCases.get(ca.Id).Status != 'Working' && ca.Status == 'Working')
            ){
                accIds.add(ca.AccountId);
            }
        }

        List<AggregateResult> closedCasesOnAccount = [SELECT COUNT(Id) numberOfCases, AccountId FROM Case WHERE AccountId IN :accIds AND Status = 'Closed' GROUP BY AccountId];
        Map<Id, Account> accToUpdate = new Map<Id, Account>();

        for(AggregateResult ar : closedCasesOnAccount){
            Integer cases = Integer.valueOf(ar.get('numberOfCases'));
            String accId = String.valueOf(ar.get('AccountId'));

            Account ac = new Account();
            ac.Id = accId;

            if(cases <= 2){
                ac.Rating = 'Cold';
            }
            else if(cases > 2 && cases <= 5){
                ac.Rating = 'Warm';
            }
            else if(cases > 5){
                ac.Rating = 'Hot';
            }
            accToUpdate.put(ac.Id, ac);
        }

        if(accToUpdate != null && accToUpdate.size() > 0){
            try {
                update accToUpdate.values();
            } catch (Exception e) {
                System.debug('DML Exception!');
            }
        }
    }

    //problem #8
    private static void countCaseStatusOnAccount(List<Case> newCases, Map<Id, Case> oldCases){
        Set<Id> accIds = new Set<Id>();
        
        if(newCases != null && newCases.size() > 0){
            for (Case c : newCases) {
                if(
                    (oldCases == null && c.Status != null && c.AccountId != null) ||
                    (oldCases != null && c.Status != oldCases.get(c.Id).Status && c.AccountId != null)
                ){
                    accIds.add(c.AccountId);
                }
            }
        }
        else{ //for AFTER_DELETE
            for (Case c : oldCases.values()) {
                if(
                    c.Status != null && c.AccountId != null
                ){
                    accIds.add(c.AccountId);
                }
            }
        }

        if(accIds != null && accIds.size() > 0){
            List<AggregateResult> caseCountList = [SELECT COUNT(Id)numberOfCases, Status, AccountId FROM Case WHERE AccountId IN :accIds GROUP BY Status, AccountId];
            Map<Id, CaseStatusOnAccount> accountStatusMap = new Map<Id, CaseStatusOnAccount>();
            List<Account> acList = new List<Account>();

            if(caseCountList != null && caseCountList.size() > 0){

                for (AggregateResult ar : caseCountList) {
                    Id accId = (Id)ar.get('AccountId');
                    String caseStatus = String.valueOf(ar.get('Status'));
                    Integer no = Integer.valueOf(ar.get('numberOfCases'));

                    if(accountStatusMap.containsKey(accId)){
                        CaseStatusOnAccount cs = accountStatusMap.get(accId);
                        if(caseStatus == 'New'){
                            cs.NewCase = no;
                        }
                        else if(caseStatus == 'Working'){
                            cs.WorkingCase = no;
                        }
                        else if(caseStatus == 'Escalated'){
                            cs.EscalatedCase = no;
                        }
                        else if(caseStatus == 'Closed'){
                            cs.ClosedCase = no;
                        }
                        accountStatusMap.put(accId, cs);
                    }
                    else{
                        CaseStatusOnAccount cs = new CaseStatusOnAccount();
                        if(caseStatus == 'New'){
                            cs.NewCase = no;
                        }
                        else if(caseStatus == 'Working'){
                            cs.WorkingCase = no;
                        }
                        else if(caseStatus == 'Escalated'){
                            cs.EscalatedCase = no;
                        }
                        else if(caseStatus == 'Closed'){
                            cs.ClosedCase = no;
                        }
                        accountStatusMap.put(accId, cs);
                    }
                }

                for(Id acid : accountStatusMap.keySet()){
                    Account ac = new Account(
                        Id = acid,
                        Case_Summary__c = JSON.serialize(accountStatusMap.get(acid))
                    );
                    acList.add(ac);
                }

                if(acList != null && acList.size() > 0){
                    update acList;
                }
            }
        }
    }

    public class CaseStatusOnAccount{
        public Integer NewCase = 0;
        public Integer WorkingCase = 0;
        public Integer EscalatedCase = 0;
        public Integer ClosedCase = 0;
    }

    //problem #15
    private static void updateAccountDescriptionAndTaskStatus(List<Case> newCases, Map<Id, Case> oldCases){
        Map<Id, Case> caseToStatus = new Map<Id, Case>();

        for (Case c : newCases) {
            if(
                oldCases != null && c.Status != oldCases.get(c.Id).Status && c.Status != null
            ){
                caseToStatus.put(c.Id, c);
            }
        }

        if(caseToStatus != null && !caseToStatus.isEmpty()){
            List<Case> caseList = [SELECT Id, AccountId FROM Case WHERE Id IN :caseToStatus.keySet() AND AccountId != null];
            List<Task> taskList = [SELECT Id, Status, WhatId FROM Task WHERE What.Type = 'Case' AND WhatId IN :caseToStatus.keySet()];
            List<sObject> recordsToUpdate = new List<sObject>(); 

            if(caseList != null && caseList.size() > 0){
                for (Case c : caseList) {
                    Account ac = new Account(
                        Id = c.AccountId,
                        Description = 'Case Updates=> '+caseToStatus.get(c.Id).CaseNumber+' & '+caseToStatus.get(c.Id).Status
                    );
                    recordsToUpdate.add(ac);
                }
            }

            if(taskList != null && taskList.size() > 0){
                for (Task t : taskList) {
                    t.Status = caseToStatus.get(t.WhatId).Status;
                    recordsToUpdate.add(t);
                }
            }

            if(recordsToUpdate != null && recordsToUpdate.size() > 0){
                try {
                    update recordsToUpdate;
                } catch (Exception e) {
                    System.debug('Exception'+e);
                }
            }
        }
    }

    //problem #17
    private static void linkCaseToPrimaryContactAndCreateEventWithSameSubject(List<Case> newCases, Map<Id, Case> oldCases){
        Set<Id> accIds = new Set<Id>();

        for (Case c : newCases) {
            if(
                (oldCases == null && c.AccountId != null) ||
                (oldCases != null && oldCases.get(c.Id).AccountId != c.AccountId && c.AccountId != null)
            ){
                accIds.add(c.AccountId);
            }
        }

        if(accIds != null && accIds.size() > 0){
            List<Contact> conList = [SELECT Id, AccountId FROM Contact WHERE Primary_Contact__c = true AND AccountId IN :accIds];
            Map<Id, Id> accIdToConId = new Map<Id, Id>();
            List<Event> eventList = new List<Event>();

            if(conList != null && conList.size() > 0){
                for (Contact c : conList) {
                    accIdToConId.put(c.AccountId, c.Id);
                }
            }

            for (Case c : newCases) {
                if(c.AccountId != null && accIdToConId.containsKey(c.AccountId)){
                    c.ContactId = accIdToConId.get(c.AccountId);

                    Event e = new Event(
                        Subject = c.Subject,
                        WhoId = accIdToConId.get(c.AccountId),
                        StartDateTime = Datetime.now(),
                        EndDateTime = Datetime.now().addDays(2)
                    );
                    eventList.add(e);
                }
                else{
                    c.addError('There is no primary contact on this case!');
                }
            }

            if(eventList != null && eventList.size() > 0){
                try {
                    insert eventList;
                } catch (Exception e) {
                    System.debug('DML insertion error!'+e);
                }
            }
        }
    }
}
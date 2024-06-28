public class OpportunityTriggerHandler {

    public static void beforeInsert(List<Opportunity> newOpps) {
        // throwErrorIfOpportunityHasCreatedOnAccountOnSameDay(newOpps);
    }

    public static void afterInsert(List<Opportunity> newOpps) {
        //createUpdateTasks(newOpps, null);
        // maxAmountOfClosedOpportunityWithoutAggrgate(newOpps, null);
        // updateAccountDescriptionToMaxOpprtunityName(newOpps, null);
        // sumOfAmountOnAccount(newOpps, null);
        // sendEmailToOpportunityOwnerIfAmountIsGreater(newOpps, null);
        // secondHighestAmountOnAccountDesc(newOpps, null);
    }

    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        // createdOpportunityRole(newOpps, oldOpps);
        //createUpdateTasks(newOpps, oldOpps);
        // maxAmountOfClosedOpportunityWithoutAggrgate(newOpps, oldOpps);
        // updateAccountDescriptionToMaxOpprtunityName(newOpps, oldOpps);
        // sumOfAmountOnAccount(newOpps, oldOpps);
        // sendEmailToOpportunityOwnerIfAmountIsGreater(newOpps, oldOpps);
        // changeOppLineItemStatusBasedOnOppStatus(newOpps, oldOpps);
        // secondHighestAmountOnAccountDesc(newOpps, oldOpps);
    }

    public static void afterDelete(Map<Id, Opportunity> oldOpps){
        // maxAmountOfClosedOpportunityWithoutAggrgate(null, oldOpps);
        // updateAccountDescriptionToMaxOpprtunityName(null, oldOpps);
        // sumOfAmountOnAccount(null, oldOpps);
        // secondHighestAmountOnAccountDesc(null, oldOpps);
    }

    public static void afterUndelete(List<Opportunity> newOpps){
        // maxAmountOfClosedOpportunityWithoutAggrgate(newOpps, null);
        // updateAccountDescriptionToMaxOpprtunityName(newOpps, null);
        // sumOfAmountOnAccount(newOpps, null);
        // secondHighestAmountOnAccountDesc(newOpps, null);
    }

    //logic-functions

    //problem #6
    private static void createdOpportunityRole(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        Map<Id, String> accIdsToOppTypeMap = new Map<Id, String>();

        for (Opportunity op : newOpps) {
            if(
                (oldOpps != null && oldOpps.get(op.Id).Type != op.Type)
            ){
                accIdsToOppTypeMap.put(op.AccountId, op.Type);
            }
        }

        List<Contact> conList = [SELECT Id, Type__c FROM Contact WHERE AccountId IN :accIdsToOppTypeMap.keySet() AND Type__c IN :accIdsToOppTypeMap.values() LIMIT 1];
        Map<String, Id> ConTypeToConMap = new Map<String, Id>();
        List<OpportunityContactRole> opConRoleList = new List<OpportunityContactRole>();

        if(!conList.isEmpty()){
            for (Contact ct : conList) {
                ConTypeToConMap.put(ct.Type__c, ct.Id);
            }
        }

        for (Opportunity op : newOpps) {
            if(ConTypeToConMap.containsKey(op.Type)){
                OpportunityContactRole opCon = new OpportunityContactRole(
                    OpportunityId = op.Id,
                    ContactId = ConTypeToConMap.get(op.Type)
                );
                opConRoleList.add(opCon);
            }
            else if(ConTypeToConMap.get(op.Type) == null || ConTypeToConMap == null){
                op.AddError('No same type of contact is available on Account!');
            }
        }

        if(!opConRoleList.isEmpty()){
            List<OpportunityContactRole> existingOpConList = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :newOpps];

            delete existingOpConList;

            insert opConRoleList;
        }
    }

    //problem #10
    private static void createUpdateTasks(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        Map<Id, String> oppIds = new Map<Id, String>();

        for (Opportunity op : newOpps) {
            if(
                (oldOpps == null && op.StageName != null) ||
                (oldOpps != null && oldOpps.get(op.Id).StageName != op.StageName && op.StageName != null)
            ){
                oppIds.put(op.Id, op.StageName);
            }
        }

        if(oppIds != null && oppIds.size() > 0){
            List<Task> taskList = [SELECT Id, WhatId, Subject, Status, Description FROM Task WHERE WhatId IN :oppIds.keySet()];
            Map<Id, Task> opIdToTaskMap = new Map<Id, Task>();
            List<Task> newTaskList = new List<Task>();

            if(taskList != null && taskList.size() > 0){

                for (Task t : taskList) {
                    opIdToTaskMap.put(t.WhatId, t);
                }
            }

            for (Id op : oppIds.keySet()) {
                if(opIdToTaskMap.containsKey(op)){
                    Task t = opIdToTaskMap.get(op);
                    t.Description = oppIds.get(op);
                    newTaskList.add(t);
                }
                else{
                    Task t = new Task(
                        WhatId = op,
                        Subject = 'New Creation!',
                        Status = 'Not Started',
                        Description = oppIds.get(op)
                    );
                    newTaskList.add(t);
                }
            }

            if(newTaskList != null && newTaskList.size() > 0){
                try {
                    upsert newTaskList;
                } catch (Exception e) {
                    System.debug('Exception'+e);
                }
            }
        }
    }

    //problem #12
    private static void maxAmountOfClosedOpportunityWithoutAggrgate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        Set<Id> accIds = new Set<Id>();

        if(newOpps != null && newOpps.size() > 0){
            for (Opportunity op : newOpps) {
                if(
                    (oldOpps == null && op.Amount != null && op.AccountId != null && op.CloseDate != null) ||
                    (oldOpps != null && oldOpps.get(op.Id).Amount != op.Amount && op.Amount != null && op.AccountId != null && op.CloseDate != null)
                ){
                    accIds.add(op.AccountId);
                }
            }
        }
        else{
            for (Opportunity op : oldOpps.values()) {
                if(op.Amount != null && op.AccountId != null && op.CloseDate != null){
                    accIds.add(op.AccountId);
                }
            }
        }

        if(accIds != null && accIds.size() > 0){
            List<Opportunity> opList = [SELECT Id, Amount, AccountId FROM Opportunity WHERE AccountId IN :accIds AND CloseDate != null AND StageName LIKE 'Closed %'];
            Map<Id, Account> accMap = new Map<Id, Account>();

            if(opList != null && opList.size() > 0){
                for (Opportunity op : opList) {
                    if(accMap.containsKey(op.AccountId)){
                        Account ac = accMap.get(op.AccountId);
                        if(op.Amount > ac.Max_Closed_Opportunity_Amount__c){
                            ac.Max_Closed_Opportunity_Amount__c = op.Amount;
                            accMap.put(op.AccountId, ac);
                        }
                    }
                    else{
                        Account ac = new Account(
                            Id = op.AccountId,
                            Max_Closed_Opportunity_Amount__c = op.Amount
                        );
                        accMap.put(op.AccountId, ac);
                    }
                }
            }

            if(accMap != null && accMap.values().size() > 0){
                try {
                    update accMap.values();
                } catch (Exception e) {
                    System.debug('Exception'+e);
                }
            }
        }
    }

    //problem #16
    private static void updateAccountDescriptionToMaxOpprtunityName(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        Set<Id> accIds = new Set<Id>();
        
        if(newOpps != null && newOpps.size() > 0){
            for (Opportunity op : newOpps) {
                if(
                    (oldOpps == null && op.AccountId != null && op.Amount != null) ||
                    (oldOpps != null && oldOpps.get(op.Id).Amount != op.Amount && op.Amount != null && op.AccountId != null) 
                ){
                    accIds.add(op.AccountId);
                }
            }
        }
        else{ //after_delete case
            for (Opportunity op : oldOpps.values()) {
                if(op.AccountId != null && op.Amount != null){
                    accIds.add(op.AccountId);
                }
            }
        }

        if(accIds != null && accIds.size() > 0){
            List<Account> accList = [SELECT Id, Description, (SELECT Id, Name, Amount FROM Opportunities ORDER BY Amount DESC LIMIT 1) FROM Account WHERE Id IN :accIds];
            List<Account> accUpdateList = new List<Account>();

            if (accList != null && accList.size() > 0) {
                for (Account ac : accList) {
                    List<Opportunity> oppList = ac.Opportunities;
                    if(oppList != null && oppList.size() > 0){
                        Account a = new Account(
                            Id = ac.Id,
                            Description = 'Max Opportunity Amount--->'+oppList[0].Amount+' Max Opportunity Name--->'+oppList[0].Name
                        );
                        accUpdateList.add(a);
                    }
                }
            }

            if(accUpdateList != null && accUpdateList.size() > 0){
                try {
                    update accUpdateList;
                } catch (Exception e) {
                    System.debug('DML Exception'+e.getMessage());
                }
            }
        }
    }

    //problem #30
    private static void sumOfAmountOnAccount(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        Set<Id> accIds = new Set<Id>();

        if(newOpps != null && newOpps.size() > 0){
            for (Opportunity op : newOpps) {
                if (
                    (oldOpps == null && op.AccountId != null && op.Amount != null) ||
                    (oldOpps != null && op.AccountId != null && op.Amount != null && oldOpps.get(op.Id).Amount != op.Amount)
                ) {
                    accIds.add(op.AccountId);
                }
            }
        }
        else{ //after undelete
            for (Opportunity op : oldOpps.values()) {
                if (op.AccountId != null && op.Amount != null) {
                    accIds.add(op.AccountId);
                }
            }
        }

        if (accIds != null && accIds.size() > 0) {
            List<AggregateResult> oppList = [SELECT SUM(Amount)totalAmount, AccountId FROM Opportunity WHERE AccountId IN :accIds GROUP BY AccountId];
            List<Account> accList = new List<Account>();

            if (oppList != null && oppList.size() > 0) {
                for (AggregateResult ar : oppList) {
                    Account a = new Account(
                        Id = (Id)ar.get('AccountId'),
                        Total_Amount_of_Opportunities__c = Integer.valueOf(ar.get('totalAmount'))
                    );
                    accList.add(a);
                }
            }

            if(accList != null && accList.size() > 0){
                try {
                    update accList;
                } catch (Exception e) {
                    System.debug('DML Exception'+e);
                }
            }
        }
    }

    //problem #40
    private static void throwErrorIfOpportunityHasCreatedOnAccountOnSameDay(List<Opportunity> newOpps) {
        Set<Id> accIds = new Set<Id>();

        for (Opportunity op : newOpps) {
            if (op.AccountId != null) {
                accIds.add(op.AccountId);
            }
        }

        if (accIds.size() > 0) {
            List<Opportunity> oppList = [SELECT Id, AccountId, CreatedDate FROM Opportunity WHERE AccountId IN :accIds];
            Map<Id, Date> accIdToCreatedDate = new Map<Id, Date>(); 

            if (oppList.size() > 0) {
                for (Opportunity op : oppList) {
                    Date d = Date.newInstance(op.CreatedDate.year(), op.CreatedDate.month(), op.CreatedDate.day());
                    accIdToCreatedDate.put(op.AccountId, d);
                }
            }

            if (accIdToCreatedDate.size() > 0) {
                for (Opportunity op : newOpps) {
                    if (accIdToCreatedDate.containsKey(op.AccountId)) {
                        Date exisitingOppDate = accIdToCreatedDate.get(op.AccountId);
                        if (Date.today().isSameDay(exisitingOppDate)) {
                            op.addError('Already Opportunity has been created on parent Account on same day :(');
                        }
                    }
                }
            }
        }
    }

    //problem #42
    private static void sendEmailToOpportunityOwnerIfAmountIsGreater(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Set<Id> oppIds = new Set<Id>();
        
        for (Opportunity op : newOpps) {
            if (op.Amount > 10000) {
                oppIds.add(op.Id);
            }
        }

        if (oppIds.size() > 0) {
            List<Opportunity> oppList = [SELECT Id, Name, Amount, Owner.Email FROM Opportunity WHERE Id IN :oppIds];
            Map<String, String> emailToBodyMap = new Map<String, String>();
            List<Messaging.SingleEmailMessage> emailNeedsToBeSentList = new List<Messaging.SingleEmailMessage>();

            for (Opportunity op : oppList) {
                emailToBodyMap.put(
                    op.Owner.Email,
                    'Opportunity Name: '+op.Name+'\n'+'Amount: '+op.Amount
                );
            }

            if (emailToBodyMap.size() > 0) {
                for (String e : emailToBodyMap.keySet()) {
                    Messaging.SingleEmailMessage ms = new Messaging.SingleEmailMessage();
                    ms.setToAddresses(new List<String>{e});
                    ms.setPlainTextBody(emailToBodyMap.get(e));
                    ms.setSubject('About Opportunity Amount!');
                    emailNeedsToBeSentList.add(ms);
                }
            }

            if (emailNeedsToBeSentList.size() > 0) {
                try {
                    Messaging.sendEmail(emailNeedsToBeSentList);
                } catch (Exception e) {
                    System.debug('Error while sending email'+e);
                }
            }
        }
    }

    //problem #43
    private static void changeOppLineItemStatusBasedOnOppStatus(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Set<Id> oppIds = new Set<Id>();

        for (Opportunity op : newOpps) {
            if (
                (op.StageName == 'Closed Won' || op.StageName == 'Closed Lost') &&
                (oldOpps.get(op.Id).StageName != op.StageName)
            ) {
                oppIds.add(op.Id);
            }
        }

        if (oppIds.size() > 0) {
            List<Opportunity> oppList = [SELECT Id, StageName, (SELECT Id, Description FROM OpportunityLineItems ORDER BY LastModifiedDate DESC) FROM Opportunity WHERE Id IN :oppIds];
            List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();

            if (oppList.size() > 0) {
                for (Opportunity op : oppList) {
                    if (op.OpportunityLineItems.size() > 0) {
                        for (Integer i = 0; i < op.OpportunityLineItems.size(); i++) {
                            if (op.StageName == 'Closed Won') {
                                op.OpportunityLineItems[i].Description = (i == 0) ? 'Approved' : 'Rejected';
                                oppLineItemList.add(op.OpportunityLineItems[i]);
                            }
                            else if (op.StageName == 'Closed Lost') {
                                op.OpportunityLineItems[i].Description = (i == 0) ? 'Lost' : 'Rejected';
                                oppLineItemList.add(op.OpportunityLineItems[i]);
                            }
                        }
                    }
                }
            }

            if (oppLineItemList.size() > 0) {
                try {
                    update oppLineItemList;
                } catch (Exception e) {
                    System.debug('Error while updatation!'+e);
                }
            }
        }
    }

    //problem #47
    private static void secondHighestAmountOnAccountDesc(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Set<Id> accIds = new Set<Id>();
        
        if (newOpps != null) {
            for (Opportunity o : newOpps) {
                if (o.AccountId != null) {
                    accIds.add(o.AccountId);
                }
            }
        }
        else if (newOpps == null) { //delete case
            for (Opportunity o : oldOpps.values()) {
                if (o.AccountId != null) {
                    accIds.add(o.AccountId);
                }
            }
        }

        if (accIds.size() > 0) {
            List<Account> accList = [SELECT Id, (SELECT Id, Amount FROM Opportunities ORDER BY Amount DESC LIMIT 2) FROM Account WHERE Id IN :accIds];
            Map<Id, String> accIdToAmountMap = new Map<Id, String>();
            List<Account> accUpdateList = new List<Account>();

            if (accList.size() > 0) {
                for (Account a : accList) {
                    if (a.Opportunities.size() == 2) { //limit 2 so works good
                        accIdToAmountMap.put(a.Id, String.valueOf(a.Opportunities[1].Amount));
                    }
                    else if (a.Opportunities.size() == 1) { //if account only has 1 opp
                        accIdToAmountMap.put(a.Id, String.valueOf(a.Opportunities[0].Amount));
                    }
                }
            }

            if (accIdToAmountMap.size() > 0) {
                for (Id i : accIdToAmountMap.keySet()) {
                    accUpdateList.add(
                        new Account(
                            Id = i,
                            Description = 'Second Highest Amount of Opportunities on this Account -----> '+accIdToAmountMap.get(i)
                        )
                    );
                }
            }

            if (accUpdateList.size() > 0) {
                try {
                    update accUpdateList;
                } catch (Exception e) {
                    System.debug('Exception while updating the accounts ==> '+e.getMessage());
                }
            }
        }
    }
}
public class OpportunityTriggerHandler {

    public static void afterInsert(List<Opportunity> newOpps) {
        //createUpdateTasks(newOpps, null);
        // maxAmountOfClosedOpportunityWithoutAggrgate(newOpps, null);
    }

    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        // createdOpportunityRole(newOpps, oldOpps);
        //createUpdateTasks(newOpps, oldOpps);
        // maxAmountOfClosedOpportunityWithoutAggrgate(newOpps, oldOpps);
    }

    public static void afterDelete(Map<Id, Opportunity> oldOpps){
        // maxAmountOfClosedOpportunityWithoutAggrgate(null, oldOpps);
    }

    public static void afterUndelete(List<Opportunity> newOpps){
        // maxAmountOfClosedOpportunityWithoutAggrgate(newOpps, null);
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
}
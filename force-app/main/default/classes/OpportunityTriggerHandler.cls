public class OpportunityTriggerHandler {

    public static void afterInsert(List<Opportunity> newOpps) {
        //createUpdateTasks(newOpps, null);
    }

    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        // createdOpportunityRole(newOpps, oldOpps);
        //createUpdateTasks(newOpps, oldOpps);
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
}
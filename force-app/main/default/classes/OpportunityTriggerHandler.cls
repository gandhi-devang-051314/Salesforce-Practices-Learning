public class OpportunityTriggerHandler {

    public static void afterInsert(List<Opportunity> newOpps) {

    }

    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        // createdOpportunityRole(newOpps, oldOpps);
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
}
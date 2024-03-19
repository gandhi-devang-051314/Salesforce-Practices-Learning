public class OpportunityLineItemTriggerHandler {

    public static void afterInsert(List<OpportunityLineItem> newOppLine){
        //oppLineItemCountOnAccount(newOppLine, null);
        // updateAccountDescriptionToOppLineDescription(newOppLine, null);
        // createAsset(newOppLine);
        // rollUpCountOnAccountWithOutAggregation(newOppLine, null);
    }    
    public static void afterUpdate(List<OpportunityLineItem> newOppLine, Map<Id, OpportunityLineItem> oldOppLine){
        //oppLineItemCountOnAccount(newOppLine, oldOppLine);
        // updateAccountDescriptionToOppLineDescription(newOppLine, oldOppLine);
        // rollUpCountOnAccountWithOutAggregation(newOppLine, oldOppLine);
    }
    public static void afterDelete(Map<Id, OpportunityLineItem> oldOppLine){
        //oppLineItemCountOnAccount(null, oldOppLine);
        // rollUpCountOnAccountWithOutAggregation(null, oldOppLine);
    }
    public static void afterUndelete(List<OpportunityLineItem> newOppLine){
        //oppLineItemCountOnAccount(newOppLine, null);
        // rollUpCountOnAccountWithOutAggregation(newOppLine, null);
    }

    public static void beforeInsert(List<OpportunityLineItem> newOppLine){
        // preventInsertion(newOppLine);
    }

    //logic functions

    //problem #9
    private static void oppLineItemCountOnAccount(List<OpportunityLineItem> newOppLine, Map<Id, OpportunityLineItem> oldOppLine){
        Set<Id> oppIds = new Set<Id>();

        if(newOppLine != null && newOppLine.size() > 0){
            for (OpportunityLineItem opp : newOppLine) {
                if( 
                    (oldOppLine == null && opp.ListPrice > 50000 && opp.OpportunityId != null) ||
                    (oldOppLine != null && oldOppLine.get(opp.Id).ListPrice != opp.ListPrice && opp.ListPrice > 50000 && opp.OpportunityId != null)
                ){
                    oppIds.add(opp.OpportunityId);
                }
            }
        }
        else{ //after_delete context
            for (OpportunityLineItem opp : oldOppLine.values()) {
                if(opp.ListPrice > 50000 && opp.OpportunityId != null){
                    oppIds.add(opp.OpportunityId);
                }
            }
        }

        if(oppIds != null && oppIds.size() > 0){
            List<AggregateResult> countOppList = [SELECT COUNT(Id)numberOfOpps, Opportunity.Account.Id FROM OpportunityLineItem WHERE OpportunityId IN :oppIds AND ListPrice > 50000 GROUP BY Opportunity.Account.Id];
            List<Account> accList = new List<Account>();

            if(countOppList != null && countOppList.size() > 0){
                for (AggregateResult ar : countOppList) {
                    Integer count = Integer.valueOf(ar.get('numberOfOpps'));
                    String accId = String.valueOf(ar.get('Id'));

                    Account ac = new Account(
                        Id = accId,
                        Opportunity_Line_Count__c = count
                    );
                    accList.add(ac);
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

    //problem #20
    private static void updateAccountDescriptionToOppLineDescription(List<OpportunityLineItem> newOppLine, Map<Id, OpportunityLineItem> oldOppLine){
        Map<Id, String> oppIdToOppLineDescMap = new Map<Id, String>();

        for (OpportunityLineItem opi : newOppLine) {
            if(
                (oldOppLine == null && opi.OpportunityId != null && opi.Description != null) ||
                (oldOppLine != null && oldOppLine.get(opi.Id).Description != opi.Description && opi.Description != null && opi.OpportunityId != null)
            ){
                oppIdToOppLineDescMap.put(opi.OpportunityId, opi.Description);
            }
        }

        if(oppIdToOppLineDescMap != null){
            List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity WHERE Id IN :oppIdToOppLineDescMap.keySet() AND AccountId != null];
            List<Account> accList = new List<Account>();

            if(oppList != null && oppList.size() > 0){
                for (Opportunity op : oppList) {
                    Account ac = new Account(
                        Id = op.AccountId,
                        Description = oppIdToOppLineDescMap.get(op.Id)
                    );
                    accList.add(ac);
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

    //problem #21
    private static void preventInsertion(List<OpportunityLineItem> newOppLine){
        Set<Id> oppIds = new Set<Id>();
        Set<Id> proIds = new Set<Id>();

        for (OpportunityLineItem opi : newOppLine) {
            if(
                opi.OpportunityId != null && opi.Product2Id != null
            ){
                oppIds.add(opi.OpportunityId);
                proIds.add(opi.Product2Id);
            }
        }

        if(oppIds != null && oppIds.size() > 0 && proIds != null && proIds.size() > 0){
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Family__c FROM Opportunity WHERE Id IN :oppIds]);
            Map<Id, Product2> proMap = new Map<Id, Product2>([SELECT Id, Family FROM Product2 WHERE Id IN :proIds]);

            if(oppMap != null && oppMap.values().size() > 0 && proMap != null && proMap.values().size() > 0){
                for (OpportunityLineItem opi : newOppLine) {
                    if(oppMap.get(opi.OpportunityId).Family__c != proMap.get(opi.Product2Id).Family){
                        opi.addError('Opportunity Family and Product Family must be same!');
                    }
                }
            }
        }
    }

    //problem #22
    private static void createAsset(List<OpportunityLineItem> newOppLine){
        Map<Id, Id> oppIdToProIdMap = new Map<Id, Id>();

        for (OpportunityLineItem oli : newOppLine) {
            if(oli.OpportunityId != null && oli.Product2Id != null){
                oppIdToProIdMap.put(oli.OpportunityId, oli.Product2Id);
            }
        }

        if(oppIdToProIdMap != null && oppIdToProIdMap.values().size() > 0){
            List<Opportunity> oppList = [SELECT Id, AccountId, Account.Name FROM Opportunity WHERE Id IN :oppIdToProIdMap.keySet() AND AccountId != null];
            List<Asset> assetList = new List<Asset>();

            if (oppList != null && oppList.size() > 0) {
                for (Opportunity op : oppList) {
                    Asset a = new Asset(
                        Name = op.Account.Name + ' OpportunityLineItem',
                        AccountId = op.AccountId
                        // Product2Id = oppIdToProIdMap.get(op.Id),
                    );
                    assetList.add(a);
                }
            }

            if(assetList != null && assetList.size() > 0){
                try {
                    insert assetList;
                } catch (Exception e) {
                    System.debug('DML Exception'+e);
                }
            }
        }
    }

    //problem #28
    private static void rollUpCountOnAccount(List<OpportunityLineItem> newOppLine, Map<Id, OpportunityLineItem> oldOppLine){
        Set<Id> oppIds = new Set<Id>();

        if (newOppLine != null && newOppLine.size() > 0) {
            for (OpportunityLineItem oli : newOppLine) {
                if (oli.OpportunityId != null) {
                    oppIds.add(oli.OpportunityId);
                }
            }
        }
        else { //after undelete
            for (OpportunityLineItem oli : oldOppLine.values()) {
                if (oli.OpportunityId != null) {
                   oppIds.add(oli.OpportunityId); 
                }
            }
        }


        if (oppIds != null && oppIds.size() > 0) {
            List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity WHERE Id IN :oppIds AND AccountId != null];
            Set<Id> accIds = new Set<Id>();

            if (oppList != null && oppList.size() > 0) {
                for (Opportunity op : oppList) {
                    accIds.add(op.AccountId);
                }
            }

            if (accIds != null && accIds.size() > 0) {
                //with aggregatedQuery
                List<AggregateResult> oppLineItemList = [SELECT COUNT(Id)oppLines, Opportunity.AccountId FROM OpportunityLineItem WHERE Opportunity.AccountId IN :accIds GROUP BY Opportunity.AccountId];
                List<Account> accList = new List<Account>();
    
                for (AggregateResult ar : oppLineItemList) {
                    Account a = new Account(
                        Id = (Id)ar.get('AccountId'),
                        Opportunity_Line_Count__c = Integer.valueOf(ar.get('oppLines'))
                    );
                    accList.add(a);
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
    }

    //problem #29
    private static void rollUpCountOnAccountWithOutAggregation(List<OpportunityLineItem> newOppLine, Map<Id, OpportunityLineItem> oldOppLine){
        Set<Id> oppIds = new Set<Id>();

        if (newOppLine != null && newOppLine.size() > 0) {
            for (OpportunityLineItem oli : newOppLine) {
                if (oli.OpportunityId != null) {
                    oppIds.add(oli.OpportunityId);
                }
            }
        }
        else { //after undelete
            for (OpportunityLineItem oli : oldOppLine.values()) {
                if (oli.OpportunityId != null) {
                   oppIds.add(oli.OpportunityId); 
                }
            }
        }

        if (oppIds != null && oppIds.size() > 0) {
            List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity WHERE Id IN :oppIds AND AccountId != null];
            Set<Id> accIds = new Set<Id>();

            if (oppList != null && oppList.size() > 0) {
                for (Opportunity op : oppList) {
                    accIds.add(op.AccountId);
                }
            }

            if (accIds != null && accIds.size() > 0) {
                //without aggregatedQuery
                List<OpportunityLineItem> oppLineItemList = [SELECT Id, Opportunity.AccountId FROM OpportunityLineItem WHERE Opportunity.AccountId IN :accIds];
                Map<Id, Account> oppLineItemCountOnAccountMap = new Map<Id, Account>();
    
                for (OpportunityLineItem oli : oppLineItemList) {
                    if (oppLineItemCountOnAccountMap.containsKey(oli.Opportunity.AccountId)) {
                        oppLineItemCountOnAccountMap.put(oli.Opportunity.AccountId, new Account(
                            Id = oli.Opportunity.AccountId,
                            Opportunity_Line_Count__c = oppLineItemCountOnAccountMap.get(oli.Opportunity.AccountId).Opportunity_Line_Count__c + 1
                        ));
                    }
                    else{
                        oppLineItemCountOnAccountMap.put(oli.Opportunity.AccountId, new Account(
                            Id = oli.Opportunity.AccountId,
                            Opportunity_Line_Count__c = 1
                        ));
                    }
                }
    
                if(oppLineItemCountOnAccountMap != null && oppLineItemCountOnAccountMap.size() > 0){
                    try {
                        update oppLineItemCountOnAccountMap.values();
                    } catch (Exception e) {
                        System.debug('DML Exception'+e);
                    }
                }
            }
        }
    }
}
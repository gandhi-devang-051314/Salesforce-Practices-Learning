public class OpportunityLineItemTriggerHandler {

    public static void afterInsert(List<OpportunityLineItem> newOppLine){
        //oppLineItemCountOnAccount(newOppLine, null);
    }    
    public static void afterUpdate(List<OpportunityLineItem> newOppLine, Map<Id, OpportunityLineItem> oldOppLine){
        //oppLineItemCountOnAccount(newOppLine, oldOppLine);
    }
    public static void afterDelete(Map<Id, OpportunityLineItem> oldOppLine){
        //oppLineItemCountOnAccount(null, oldOppLine);
    }
    public static void afterUndelete(List<OpportunityLineItem> newOppLine){
        //oppLineItemCountOnAccount(newOppLine, null);
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
}
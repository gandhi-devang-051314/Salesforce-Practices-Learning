public class OpportunityContactRoleTriggerHandler {

    public static void beforeInsert(List<OpportunityContactRole> newOppCons){
        //preventDuplicationAndCloseOpps(newOppCons);
    }


    //logic functions

    //problem #14
    private static void preventDuplicationAndCloseOpps(List<OpportunityContactRole> newOppCons){
        Map<Id, Id> oppToConMap = new Map<Id, Id>();
        Map<Id, Id> conToOppMap = new Map<Id, Id>();

        for (OpportunityContactRole oppCon : newOppCons) {
            if(oppCon.ContactId != null && oppCon.OpportunityId != null){
                oppToConMap.put(oppCon.OpportunityId, oppCon.ContactId);
                conToOppMap.put(oppCon.ContactId, oppCon.OpportunityId);
            }
        }

        if(oppToConMap != null && conToOppMap != null){
            Map<Id ,Opportunity> opMap = new Map<Id, Opportunity>([SELECT Id, IsClosed FROM Opportunity WHERE Id IN :oppToConMap.keySet()]);

            List<OpportunityContactRole> opConList = [SELECT Id, OpportunityId, ContactId FROM OpportunityContactRole WHERE OpportunityId IN :oppToConMap.keySet() AND ContactId IN :conToOppMap.keySet()];
            Map<String, OpportunityContactRole> opConMap = new Map<String, OpportunityContactRole>();

            if(opConList != null && opConList.size() > 0){
                for (OpportunityContactRole opCon : opConList) {
                    opConMap.put(opCon.OpportunityId+'-'+opCon.ContactId, opCon);
                }
            }

            for (OpportunityContactRole opCon : newOppCons) {
                if(opMap.containsKey(opCon.OpportunityId) && opMap.get(opCon.OpportunityId).IsClosed == true){
                    opCon.addError('Opportunity is closed!');
                }

                if(opConMap.containsKey(opCon.OpportunityId+'-'+opCon.ContactId)){
                    opCon.addError('Duplicate record found!');
                }
            }
        }
    }
}
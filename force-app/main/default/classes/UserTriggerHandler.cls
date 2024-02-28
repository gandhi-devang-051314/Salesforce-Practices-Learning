public class UserTriggerHandler {

    public static void afterUpdate(List<User> newUsers, Map<Id, User> oldUsers){
        //assignActiveOppsToManager(newUsers, oldUsers);
    }


    //logic functions

    //problem #13
    private static void assignActiveOppsToManager(List<User> newUsers, Map<Id, User> oldUsers){
        Map<Id, Id> userIdToManagerIdMap = new Map<Id, Id>();
        
        for (User u : newUsers) {
            if(
                (oldUsers != null && oldUsers.get(u.Id).isActive != u.isActive && u.isActive == false && u.ManagerId != null)
            ){
                userIdToManagerIdMap.put(u.Id, u.ManagerId);
            }
        }

        //use future method for this, as we need more extend governer limits 
        if(userIdToManagerIdMap != null){
            List<Opportunity> opList = [SELECT Id, OwnerId FROM Opportunity WHERE IsClosed = false AND OwnerId IN :userIdToManagerIdMap.keySet()];
            
            if(opList != null && opList.size() > 0){
                for (Opportunity op : opList) {
                    op.OwnerId = userIdToManagerIdMap.get(op.OwnerId);
                }

                try {
                    update opList;
                } catch (Exception e) {
                    System.debug('Exception'+e);
                }
            }
        }
    }
}
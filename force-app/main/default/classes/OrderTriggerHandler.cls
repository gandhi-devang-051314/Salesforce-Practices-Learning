public class OrderTriggerHandler {

    public static void beforeUpdate(List<Order> newOrders, Map<Id, Order> oldOrders) {
        // maximumStageWhereOrderStayedIn(newOrders, oldOrders);
        // particularStageWhereOrderStayedIn(newOrders, oldOrders);
    }



    //logic functions

    //Problem #41
    private static void maximumStageWhereOrderStayedIn(List<Order> newOrders, Map<Id, Order> oldOrders) {

        for (Order o : newOrders) {
            if (o.Status != null && o.Status != oldOrders.get(o.Id).Status) {
                Order oldOrder = oldOrders.get(o.Id);

                Long newDiff = System.now().getTime() - oldOrder.LastModifiedDate.getTime();
                Long oldDiff;

                if (oldOrder.Maximum_stage_in_Order_stayed_in_time__c == null) {
                    oldDiff = 0;
                }
                else{
                    OrderMaxStageTimeWrapper omst = (OrderMaxStageTimeWrapper)JSON.deserialize(oldOrder.Maximum_stage_in_Order_stayed_in_time__c, OrderMaxStageTimeWrapper.class);
                    oldDiff = omst.miliSeconds;
                }

                if (newDiff > oldDiff) {
                    o.Maximum_stage_in_Order_stayed__c = o.Status;
                    
                    OrderMaxStageTimeWrapper omst = new OrderMaxStageTimeWrapper();
                    omst.miliSeconds = newDiff;
                    omst.seconds = omst.miliSeconds / 1000;
                    omst.minutes = omst.seconds / 60;
                    omst.hours = omst.minutes / 60;
                    omst.days = omst.hours / 24;
                    
                    o.Maximum_stage_in_Order_stayed_in_time__c = JSON.serialize(omst);
                }
            }
        }
    }

    //problem #50
    private static void particularStageWhereOrderStayedIn(List<Order> newOrders, Map<Id, Order> oldOrders) {

        for (Order o : newOrders) {
            if (o.Status != null && o.Status != oldOrders.get(o.Id).Status) {
                Order oldOrder = oldOrders.get(o.Id);
                Long newDiff = System.now().getTime() - oldOrder.LastModifiedDate.getTime();
                List<ParticularOrderStageTimeWrapper> pList = new List<ParticularOrderStageTimeWrapper>();

                if (oldOrder.StageHistoryJSON__c == null) {
                    ParticularOrderStageTimeWrapper pw = new ParticularOrderStageTimeWrapper();
                    pw.fromStage = oldOrder.Status;
                    pw.toStage = o.Status;
                    pw.miliSeconds = newDiff;
                    pw.seconds = newDiff / 1000;
                    pw.minutes = (newDiff / 1000) / 60;
                    pw.hours = ((newDiff / 1000) / 60) / 60;
                    pw.days = (((newDiff / 1000) / 60) / 60) / 2;

                    pList.add(pw);
                }
                else {
                    pList = (List<ParticularOrderStageTimeWrapper>)JSON.deserialize(oldOrder.StageHistoryJSON__c, List<ParticularOrderStageTimeWrapper>.class); 

                    ParticularOrderStageTimeWrapper pw = new ParticularOrderStageTimeWrapper();
                    pw.fromStage = oldOrder.Status;
                    pw.toStage = o.Status;
                    pw.miliSeconds = newDiff;
                    pw.seconds = newDiff / 1000;
                    pw.minutes = (newDiff / 1000) / 60;
                    pw.hours = ((newDiff / 1000) / 60) / 60;
                    pw.days = (((newDiff / 1000) / 60) / 60) / 2;

                    pList.add(pw);
                }

                o.StageHistoryJSON__c = JSON.serialize(pList);
            }
        }
    }

    public class OrderMaxStageTimeWrapper {
        public Long miliSeconds;
        public Long seconds;
        public Long minutes;
        public Long hours;
        public Long days; 
    }

    public class ParticularOrderStageTimeWrapper {
        public String fromStage;
        public String toStage;
        public Long miliSeconds;
        public Long seconds;
        public Long minutes;
        public Long hours;
        public Long days;  
    }
}
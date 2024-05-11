public class OrderTriggerHandler {

    public static void beforeUpdate(List<Order> newOrders, Map<Id, Order> oldOrders) {
        // maximumStageWhereOrderStayedIn(newOrders, oldOrders);
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

    public class OrderMaxStageTimeWrapper {
        public Long miliSeconds;
        public Long seconds;
        public Long minutes;
        public Long hours;
        public Long days; 
    }
}
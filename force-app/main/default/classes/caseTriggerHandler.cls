public class caseTriggerHandler {

    public static void beforeInsert(List<Case> newCases){
        // suppliedEmail(newCases, null);
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldCases){
        // suppliedEmail(newCases, oldCases);
    }

    //problem statements
    //Problem #2
    private static void suppliedEmail(List<Case> newCases, Map<Id, Case> oldCases){
        Set<String> caseEmails = new Set<String>();

        for(Case c : newCases){
            if(
                (oldCases == null && c.Supplied_Email__c != null) ||
                (oldCases == null && c.Supplied_Email__c != null && oldCases.get(c.Id).Supplied_Email__c != c.Supplied_Email__c)
            ){
                caseEmails.add(c.Supplied_Email__c);
            }
        }

        List<Contact> contactRecordMap = [SELECT Id, Email FROM Contact WHERE Email IN :caseEmails];
        Map<String, Id> contactEmailToIdMap = new Map<String, Id>();

        for(Contact c : contactRecordMap){
            contactEmailToIdMap.put(c.Email, c.Id);
        }

        List<Contact> conList = new List<Contact>();
        Map<String, Id> conEmailToIdMap = new Map<String, Id>();

        for(Case c :newCases){
            if(contactEmailToIdMap.containsKey(c.Supplied_Email__c) && c.Supplied_Email__c != null){
                c.ContactId = contactEmailToIdMap.get(c.Supplied_Email__c);
            }
            else{
                Contact con = new Contact(
                    LastName = 'Test Contact',
                    Email = c.Supplied_Email__c
                );
                conList.add(con);
            }
        }

        if(!conList.isEmpty()){
            try {
                insert conList;
            } catch (Exception e) {
                System.debug('Exception occured!'+e);
            }
        }

        for(Contact c : conList){
            conEmailToIdMap.put(c.Email, c.Id);
        }

        for (Case c : newCases) {
            if(c.Supplied_Email__c != null && conEmailToIdMap.containsKey(c.Supplied_Email__c)){
                c.ContactId = conEmailToIdMap.get(c.Supplied_Email__c);
            }
        }
    }
}
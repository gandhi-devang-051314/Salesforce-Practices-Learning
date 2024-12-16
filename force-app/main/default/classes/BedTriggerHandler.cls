public class BedTriggerHandler {

    public static void afterUpdate(List<Bed__c> bedList, Map<Id, Bed__c> oldBedMap) {
        // assignBedToPatient(bedList, oldBedMap);
    }

    //LOGIC FUNCTIONS---------------------------------------------------------------------------------------------

    //problem #55
    private static void assignBedToPatient(List<Bed__c> bedList, Map<Id, Bed__c> oldBedMap) {
        Set<Id> beds = new Set<Id>();

        for (Bed__c b : bedList) {
            if (b.Status__c == 'Available' && oldBedMap.get(b.Id).Status__c == 'Occupied') {
                beds.add(b.Id);
            }
        }

        if (beds.size() > 0) {
            List<Waiting_List__c> waitingPatientsList = [SELECT Id, Patient__r.Priority__c, Patient__c FROM Waiting_List__c];

            if (waitingPatientsList.size() > 0) {
                Map<String, List<Id>> categoryWiseWaitingList = new Map<String, List<Id>>();
                List<Id> sortedPatientsByCategory = new List<Id>();
                List<SObject> recordsNeedsProcess = new List<SObject>();
                Map<Id, Waiting_List__c> patientToWaitingListMap = new Map<Id, Waiting_List__c>();
                List<Waiting_List__c> waitingListNeedsToBeDeleted = new List<Waiting_List__c>();
    
                for (Waiting_List__c wl : waitingPatientsList) {
                    if (!categoryWiseWaitingList.containsKey(wl.Patient__r.Priority__c)) {
                        categoryWiseWaitingList.put(wl.Patient__r.Priority__c, new List<Id>());
                    }
                    categoryWiseWaitingList.get(wl.Patient__r.Priority__c).add(wl.Patient__c);
                    patientToWaitingListMap.put(wl.Patient__c, wl);
                }
    
                for (String s : new List<String>{'Critical', 'Emergency', 'Normal'}) {
                    if (categoryWiseWaitingList.containsKey(s)) {
                        sortedPatientsByCategory.addAll(categoryWiseWaitingList.get(s));
                    }
                }
    
                for (Id b : beds) {
                    Patient__c p = new Patient__c();
                    p.Id = sortedPatientsByCategory[0];
                    p.Assigned_Bed__c = b;
                    p.Admission_Status__c = 'Admitted';
                    recordsNeedsProcess.add(p);
    
                    Bed__c bd = new Bed__c();
                    bd.Id = b;
                    bd.Status__c = 'Occupied';
                    recordsNeedsProcess.add(bd);
    
                    sortedPatientsByCategory.remove(0);
                    waitingListNeedsToBeDeleted.add(patientToWaitingListMap.get(p.Id));
                }

                if (recordsNeedsProcess.size() > 0) {
                    update recordsNeedsProcess;
                }

                if (waitingListNeedsToBeDeleted.size() > 0) {
                    delete waitingListNeedsToBeDeleted;
                }
            }
        }
    }
}
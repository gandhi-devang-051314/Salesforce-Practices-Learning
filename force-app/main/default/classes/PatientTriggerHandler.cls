public class PatientTriggerHandler {

    public static void afterInsert(List<Patient__c> patientList) {
        // assignedPatientToBed(patientList);
    }

    public static void afterUpdate(List<Patient__c> patientList, Map<Id, Patient__c> oldPatientMap) {
        // assignedPatientToBed(patientList);
    }

    //LOGIC FUNCTIONS---------------------------------------------------------------------------------------------

    //problem #53
    private static void assignedPatientToBed(List<Patient__c> patientList) {
        Map<String, List<Id>> patientStatusMap = new Map<String, List<Id>>();

        for (Patient__c p : patientList) {
            if (p.Priority__c != null && p.Admission_Status__c != null && p.Admission_Status__c != 'In Treatment' && p.Admission_Status__c != 'Admitted') {
                if (!patientStatusMap.containsKey(p.Priority__c)) {
                    patientStatusMap.put(p.Priority__c, new List<Id>());
                }
                patientStatusMap.get(p.Priority__c).add(p.Id);
            }
        }

        if (patientStatusMap.size() > 0) {
            List<Bed__c> bedList = [SELECT Id, Category__c FROM Bed__c WHERE Status__c = 'Available' AND Category__c IN :patientStatusMap.keySet()];
            Map<String, List<Id>> bedStatusMap = new Map<String, List<Id>>();
            List<SObject> recordsForProcess = new List<SObject>();

            for (Bed__c b : bedList) {
                if (!bedStatusMap.containsKey(b.Category__c)) {
                    bedStatusMap.put(b.Category__c, new List<Id>());
                }
                bedStatusMap.get(b.Category__c).add(b.Id);
            }

            for (String s : patientStatusMap.keySet()) {
                for (Id i : patientStatusMap.get(s)) {
                    if (bedStatusMap.containsKey(s)) {
                        if (bedStatusMap.get(s).size() > 0) { //bed available for patient
                            Patient__c p = new Patient__c();
                            p.Id = i;
                            p.Assigned_Bed__c = bedStatusMap.get(s)[0];
                            p.Admission_Status__c = 'In Treatment';
                            recordsForProcess.add(p);

                            Bed__c b = new Bed__c();
                            b.Id = bedStatusMap.get(s)[0];
                            b.Status__c = 'Occupied';
                            recordsForProcess.add(b);

                            bedStatusMap.get(s).remove(0); //remove used beds from list...

                            continue; //avoid to go to down...
                        }
                    } //bed not available, need to create waiting list...
                    Waiting_List__c wl = new Waiting_List__c();
                    wl.Patient__c = i;
                    wl.Status__c = 'Waiting for Bed';
                    recordsForProcess.add(wl);
                }
            }

            if (recordsForProcess.size() > 0) {
                upsert recordsForProcess;
            }
        }
    }
}
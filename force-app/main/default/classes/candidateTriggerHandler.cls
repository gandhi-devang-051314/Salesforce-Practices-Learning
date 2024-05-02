public class candidateTriggerHandler {

    public static void afterInsert(List<Candidate__c> newCandidates) {
        // connectCandidateWithSkillsOnCandidateSkillsJunction(newCandidates);
    }

    //logic functions

    //problem #38
    private static void connectCandidateWithSkillsOnCandidateSkillsJunction(List<Candidate__c> newCandidates) {
        Map<Id, String> candidateIdWithSkillMap = new Map<Id, String>();

        for (Candidate__c c : newCandidates) {
            if (c.SkillSet__c != null && c.SkillSet__c != '') {
                candidateIdWithSkillMap.put(c.Id, c.SkillSet__c);
            }
        }

        if (candidateIdWithSkillMap.size() > 0) {
            List<Skill__c> skillList = [SELECT Id, Name FROM Skill__c];
            Map<String, Id> skillNameWithIdMap = new Map<String, Id>();
            Map<String, Id> newSkillWithCandidateIdMap = new Map<String, Id>();
            List<Skill__c> newSkillList = new List<Skill__c>();
            List<Candidate_Skill__c> candidateSkillSetList = new List<Candidate_Skill__c>();

            if (skillList.size() > 0) {
                for (Skill__c s : skillList) {
                    skillNameWithIdMap.put(s.Name, s.Id);
                }
            }

            for (Id cId : candidateIdWithSkillMap.keySet()) {
                List<String> skillSets = candidateIdWithSkillMap.get(cId).split(',');
                for (String skill : skillSets) {
                    if (skillNameWithIdMap.containsKey(skill)) {
                        candidateSkillSetList.add(
                            new Candidate_Skill__c(
                                Candidate__c = cId,
                                Skill__c = skillNameWithIdMap.get(skill)
                            )
                        );
                    }
                    else{
                        newSkillList.add(
                            new Skill__c(
                                Name = skill
                            )
                        );
                        newSkillWithCandidateIdMap.put(skill, cId);
                    }
                }
            }

            if (newSkillList.size() > 0) {
                try {
                    insert newSkillList;
                } catch (Exception e) {
                    System.debug('new skills insertion Error'+e);
                }

                for (Skill__c s : newSkillList) {
                    candidateSkillSetList.add(
                        new Candidate_Skill__c(
                            Candidate__c = newSkillWithCandidateIdMap.get(s.Name),
                            Skill__c = s.Id
                        )
                    );
                }
            }

            if (candidateSkillSetList.size() > 0) {
                try {
                    insert candidateSkillSetList;
                } catch (Exception e) {
                    System.debug('new candidateSkillSets insertion Error'+e);
                }
            }
        }
    }
}
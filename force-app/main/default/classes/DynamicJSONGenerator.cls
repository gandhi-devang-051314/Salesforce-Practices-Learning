public class DynamicJSONGenerator {

    public static void generateJSON(String Id) {
        List<Dynamic_JSON_Gen__mdt > getFieldsMapToJSONList = [SELECT Id, FieldName__c, JSON_Attribute__c, SobjectName__c FROM Dynamic_JSON_Gen__mdt WHERE IsActive__c = true];

        Map<String, Object> result = new Map<String, Object>();
        Map<String, String> mapsOfQuery = new Map<String, String>();
        Map<String, String> fieldsMappping = new Map<String, String>();
        String parentObj;

        for(Dynamic_JSON_Gen__mdt djson : getFieldsMapToJSONList) {
            if (djson.FieldName__c.contains('.')) {
                String beforeString = djson.FieldName__c.subStringBefore('.');
                String afterString = djson.FieldName__c.subStringAfter('.');
                fieldsMappping.put(djson.FieldName__c, djson.JSON_Attribute__c);

                if (mapsOfQuery.containsKey(beforeString)) {
                    String subQuery = mapsOfQuery.get(beforeString);
                    subQuery = subQuery + ', ' + afterString;
                    mapsOfQuery.put(beforeString, subQuery);
                }
                else{
                    mapsOfQuery.put(beforeString, 'SELECT Id, '+afterString);
                }
            }
            else {
                String combo = 'parent~'+djson.SobjectName__c;
                parentObj = djson.SobjectName__c;
                fieldsMappping.put(djson.FieldName__c, djson.JSON_Attribute__c);

                if (mapsOfQuery.containsKey(combo)) {
                    String subQuery = mapsOfQuery.get(combo);
                    subQuery = subQuery + ', ' + djson.FieldName__c;
                    mapsOfQuery.put(combo, subQuery);
                }
                else {
                    mapsOfQuery.put(combo, 'SELECT Id, '+djson.FieldName__c);
                }
            }


            if (!djson.JSON_Attribute__c.contains(':') && !djson.JSON_Attribute__c.contains('||')) {
                result.put(djson.JSON_Attribute__c, '');
            }
            else {

            }
        }

        // System.debug(mapsOfQuery);

        String mainQuery = mapsOfQuery.get('parent~'+parentObj);

        for (String q : mapsOfQuery.keySet()) {
            if (q != 'parent~'+parentObj) {
                String s = mapsOfQuery.get(q);
                s = s + ' FROM ' + q;
                mainQuery = mainQuery + ', (' + s + ')';
            }
        }
        mainQuery = mainQuery + ' FROM ' + parentObj + ' WHERE Id =: Id';

        // System.debug(mainQuery);

        List<sObject> recordList = Database.Query(mainQuery);
        Map<String, List<Object>> dataMappingJsonNode = new Map<String, List<Object>>();

        for (sObject sobj : recordList) {
            Map<String, Object> fieldsToValue = sobj.getPopulatedFieldsAsMap();
            for (String field : fieldsMappping.keySet()) {
                if (field.contains('.')) {
                    String before = field.subStringBefore('.');
                    String after = field.subStringAfter('.');

                    List<sObject> dataList = (List<sObject>)fieldsToValue.get(before);
                    List<Object> addDataList = new List<Object>();

                    if (dataList != null && dataList.size() > 0) {
                        for (sObject obj : dataList) {
                            Map<String, Object> fieldsToValueDataList = obj.getPopulatedFieldsAsMap();
                            Object data = fieldsToValueDataList.get(after);
                            addDataList.add(data);
                        }   
                        dataMappingJsonNode.put(fieldsMappping.get(field), addDataList);
                    }
                    else{
                        addDataList.add(null);
                        dataMappingJsonNode.put(fieldsMappping.get(field), addDataList);
                    }
                }
                else{
                    List<Object> addObjectList = new List<Object>();
                    Object data = fieldsToValue.get(field);
                    addObjectList.add(data);
                    dataMappingJsonNode.put(fieldsMappping.get(field), addObjectList);
                }
            }
        }
        System.debug(JSON.serialize(dataMappingJsonNode));
        generateRandomJSON(dataMappingJsonNode);
    }

    public static void generateRandomJSON(Map<String, List<Object>> result) {
        Map<String, Object> root = new Map<String, Object>();
        List<String> nodes = new List<String>();
        List<List<Object>> values = result.values();
        nodes.addAll(result.keySet());

        for (Integer j = 0; j < nodes.size(); j++) {
            String name = nodes[j];
            List<Object> value = values[j];

            Map<String, Object> m = root;
            List<Map<String, Object>> nestedArrayList = null;

            List<String> parts = name.split('\\:');

            for (Integer i = 0; i < parts.size(); i++) {
                String part = parts[i];
                // System.debug(part);
                if (i == parts.size() - 1) {
                    if(part.contains('||')) {
                        List<Object> addList = new List<Object>();
                        for (Object v : value) {
                            addList.add(v);
                            m.put(part.subStringBefore('||'), addList);
                        }
                    }
                    else {
                        Map<String, Object> addMap = m.clone();
                        // for (Object v : value) {
                        //     System.debug('map'+m);
                        //     System.debug('Outvalue'+v);
                        //     if (m.containsKey(part)) {
                        //         m.clear();
                        //         m.put(part, v);
                        //         if (nestedArrayList != null && parts[i - 1].contains('||')) {
                        //             nestedArrayList.add(m);
                        //             System.debug('array'+nestedArrayList);
                        //         }
                        //     }
                        //     else{
                        //         m.put(part, v);
                        //     }
                        //     System.debug('afterMap'+m);
                        //     System.debug('final'+root);
                        // }
                        
                        for (Integer g = 0; g < value.size(); g++) {
                            if (nestedArrayList != null) {
                                if (nestedArrayList.size() > g && nestedArrayList[g] != null) {
                                    System.debug('IF BEFORE map'+m);
                                    if (parts[i - 1].contains('||')) {
                                        m = (Map<String, Object>)nestedArrayList[g];
                                        m.put(part, value[g]);
                                    }
                                    else{
                                        addMap.put(part, value[g]);
                                    }
                                    System.debug('IF map'+m);
                                    
                                    System.debug('IF Outvalue'+value[g]);
                                    
                                    System.debug('IF After map'+m);
                                }
                                else{
                                    System.debug('ELSE map'+addMap);
                                    System.debug('ELSE Outvalue'+value[g]);
                                    addMap.put(part, value[g]);
                                    nestedArrayList.add(addMap);
                                    System.debug('ELSE After map'+addMap);
                                }
                            }
                            else{
                                System.debug('OUT map'+m);
                                System.debug('OUT Outvalue'+value[g]);
                                m.put(part, value[g]);
                                System.debug('OUT After map'+m);
                            }
                        }
                    }
                }
                else {
                    if (part.contains('||')) {
                        nestedArrayList = (List<Map<String, Object>>) m.get(part.subStringBefore('||'));
                        if (nestedArrayList == null) {
                            nestedArrayList = new List<Map<String, Object>>();
                            Map<String, Object> mm = new Map<String, Object>();
                            nestedArrayList.add(mm);
                            m.put(part.subStringBefore('||'), nestedArrayList);
                            m = (Map<String, Object>)nestedArrayList[0];
                        }
                        else{
                            m = (Map<String, Object>)nestedArrayList[0];
                        }
                    }
                    else{
                        Map<String, Object> mm = (Map<String, Object>) m.get(part);
                        if (mm == null) {
                            mm = new Map<String, Object>();
                            m.put(part, mm);
                        }
                        m = mm;
                    }
                }
            }
        }


        String jsonString = JSON.serialize(root);
        System.debug(jsonString);
    }


    //https://salesforce.stackexchange.com/questions/176071/how-can-i-dynamically-create-json-from-many-dot-separated-strings-for-example-p
}
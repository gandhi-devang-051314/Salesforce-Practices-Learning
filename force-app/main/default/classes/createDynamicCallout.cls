public with sharing class createDynamicCallout {

    public static HttpResponse createCall(Map<String, Object> headers, Map<String, Object> query, String reqBody, String endPoint, String calloutType, Integer timeOut){
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setMethod(calloutType);
        request.setTimeout(timeOut);

        if(headers != null && !headers.isEmpty()){
            for (String header : headers.keySet()) {
                request.setHeader(header, String.valueOf(headers.get(header)));
            }
        }

        if(query != null && !query.isEmpty()){
            String queryParams = '?';            
            List<String> queryStrings = new List<String>();
            queryStrings.addAll(query.keySet());

            for (Integer i = 0; i < queryStrings.size(); i++) {
                if(i == queryStrings.size() - 1){
                    queryParams += queryStrings[i]+'='+String.valueOf(query.get(queryStrings[i]));
                }
                else{
                    queryParams += queryStrings[i]+'='+String.valueOf(query.get(queryStrings[i]))+'&';
                }
            }
            endPoint += queryParams;
        }

        if(reqBody != null){
            request.setBody(reqBody);
        }
        request.setEndPoint(endPoint);
        System.debug('endpoint'+endPoint);
        System.debug('request'+request);

        HttpResponse response = http.send(request);
        return response;
    }
}
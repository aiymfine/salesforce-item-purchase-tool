public with sharing class UnsplashController {

    @AuraEnabled(cacheable=true)
    public static String searchImage(String query) {
        // Unsplash API key should be set as a Named Credential or Remote Site Setting
        // For this implementation, we use a custom metadata type
        String accessKey = '';

        // Try to get from custom setting
        List<UnsplashSettings__c> settings = UnsplashSettings__c.getall().values();
        if (!settings.isEmpty()) {
            accessKey = settings[0].AccessKey__c;
        }

        if (String.isBlank(accessKey)) {
            return null;
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.unsplash.com/search/photos?query=' + EncodingUtil.urlEncode(query, 'UTF-8') + '&per_page=1');
        request.setHeader('Authorization', 'Client-ID ' + accessKey);
        request.setHeader('Accept', 'application/json');
        request.setMethod('GET');
        request.setTimeout(10000);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                String responseBody = response.getBody();
                // Parse the response to get the first image URL
                // Unsplash returns: {"results": [{"urls": {"regular": "...", "small": "..."}}]}
                // Use a simple string extraction for the first image URL
                Integer resultsIndex = responseBody.indexOf('"results"');
                if (resultsIndex > -1) {
                    Integer urlsIndex = responseBody.indexOf('"urls"', resultsIndex);
                    if (urlsIndex > -1) {
                        Integer regularIndex = responseBody.indexOf('"regular"', urlsIndex);
                        if (regularIndex > -1) {
                            Integer colonIndex = responseBody.indexOf('"', regularIndex + 10);
                            Integer startUrl = responseBody.indexOf('"', colonIndex + 1) + 1;
                            Integer endUrl = responseBody.indexOf('"', startUrl);
                            return responseBody.substring(startUrl, endUrl);
                        }
                    }
                }
            }
        } catch (CalloutException e) {
            System.debug('Unsplash API call failed: ' + e.getMessage());
        }

        return null;
    }
}

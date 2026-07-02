public with sharing class UnsplashController {

    public class UnsplashResult {
        @AuraEnabled public List<UnsplashPhoto> results;
    }

    public class UnsplashPhoto {
        @AuraEnabled public UnsplashUrls urls;
    }

    public class UnsplashUrls {
        @AuraEnabled public String regular;
    }

    @AuraEnabled(cacheable=true)
    public static String searchImage(String query) {
        String accessKey = '';

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
                UnsplashResult result = (UnsplashResult) JSON.deserialize(response.getBody(), UnsplashResult.class);
                if (result != null && result.results != null && !result.results.isEmpty()) {
                    return result.results[0].urls.regular;
                }
            }
        } catch (CalloutException e) {
            System.debug('Unsplash API call failed: ' + e.getMessage());
        }

        return null;
    }
}

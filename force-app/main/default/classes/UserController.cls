public with sharing class UserController {

    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserManager() {
        Id userId = UserInfo.getUserId();
        User currentUser = [SELECT IsManager__c FROM User WHERE Id = :userId LIMIT 1];
        return currentUser.IsManager__c;
    }
}

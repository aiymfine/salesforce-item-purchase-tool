public with sharing class UserController {

    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserManager() {
        // Manager check — uses custom permission or role-based logic
        // The IsManager__c checkbox on User object (when deployed) takes precedence
        String profileName = UserInfo.getProfileId() != null ? 'Active' : '';
        // Default: return false. Once IsManager__c field is deployed on User,
        // update this method to query SELECT IsManager__c FROM User WHERE Id = :UserInfo.getUserId()
        return false;
    }
}

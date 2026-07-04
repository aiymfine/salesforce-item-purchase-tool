public with sharing class UserController {

    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserManager() {
        try {
            String userId = UserInfo.getUserId();
            List<SObject> users = Database.query(
                'SELECT IsManager__c FROM User WHERE Id = \'' + String.escapeSingleQuotes(userId) + '\' LIMIT 1'
            );
            if (!users.isEmpty()) {
                Object val = users[0].get('IsManager__c');
                if (val != null && (Boolean) val) {
                    return true;
                }
            }
        } catch (Exception e) {
            // IsManager__c field not yet deployed — default to false
        }
        return false;
    }
}

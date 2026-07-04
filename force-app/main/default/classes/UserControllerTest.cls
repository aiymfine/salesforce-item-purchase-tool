@isTest
public without sharing class UserControllerTest {

    @isTest
    static void testIsCurrentUserManagerFallback() {
        Test.startTest();
        Boolean result = UserController.isCurrentUserManager();
        Test.stopTest();
        // Returns false when IsManager__c field is not deployed or user is not a manager
        System.assertEquals(false, result);
    }
}

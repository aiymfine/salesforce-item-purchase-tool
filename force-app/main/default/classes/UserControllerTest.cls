@isTest
public without sharing class UserControllerTest {

    @isTest
    static void testIsCurrentUserManagerFieldNotExists() {
        Test.startTest();
        Boolean result = UserController.isCurrentUserManager();
        Test.stopTest();
        System.assertEquals(false, result);
    }
}

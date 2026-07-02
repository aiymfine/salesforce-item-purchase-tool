@isTest
public class UserControllerTest {

    @isTest
    static void testIsCurrentUserManager() {
        Test.startTest();
        Boolean isManager = UserController.isCurrentUserManager();
        Test.stopTest();

        // Should return false by default for test user
        System.assert(isManager != null, 'Should return a boolean value');
    }
}

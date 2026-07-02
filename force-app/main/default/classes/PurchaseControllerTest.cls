@isTest
public class PurchaseControllerTest {

    static Id accountId;

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        accountId = acc.Id;

        List<Item__c> items = new List<Item__c>();
        for (Integer i = 0; i < 3; i++) {
            items.add(new Item__c(
                Name = 'Test Item ' + i,
                Type__c = 'Hardware',
                Family__c = 'Electronics',
                Price__c = 10.00 + i * 5,
                AvailableQuantity__c = 10
            ));
        }
        insert items;
    }

    @isTest
    static void testSuccessfulCheckout() {
        List<Item__c> items = [SELECT Id, Price__c FROM Item__c LIMIT 2];
        
        List<PurchaseController.CartItem> cartItems = new List<PurchaseController.CartItem>();
        cartItems.add(new PurchaseController.CartItem(items[0].Id, 2, items[0].Price__c));
        cartItems.add(new PurchaseController.CartItem(items[1].Id, 1, items[1].Price__c));

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, cartItems);
        Test.stopTest();

        System.assertTrue(result.success);
        System.assertNotEquals(null, result.purchaseId);

        // Verify purchase was created
        Purchase__c purchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :result.purchaseId];
        System.assertEquals(3, purchase.TotalItems__c); // 2 + 1
        System.assertEquals(35, purchase.GrandTotal__c); // 2*10 + 1*15

        // Verify purchase lines
        List<PurchaseLine__c> lines = [SELECT Amount__c, UnitCost__c FROM PurchaseLine__c WHERE PurchaseId__c = :result.purchaseId];
        System.assertEquals(2, lines.size());

        // Verify stock decreased
        items = [SELECT Id, AvailableQuantity__c FROM Item__c ORDER BY Name];
        System.assertEquals(8, items[0].AvailableQuantity__c); // 10 - 2
        System.assertEquals(9, items[1].AvailableQuantity__c); // 10 - 1
        System.assertEquals(10, items[2].AvailableQuantity__c); // unchanged
    }

    @isTest
    static void testCheckoutEmptyCart() {
        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, new List<PurchaseController.CartItem>());
        Test.stopTest();

        System.assertFalse(result.success);
        System.assertEquals('Cart is empty.', result.message);
    }

    @isTest
    static void testCheckoutInsufficientStock() {
        Item__c item = [SELECT Id, Price__c, AvailableQuantity__c FROM Item__c LIMIT 1];
        
        List<PurchaseController.CartItem> cartItems = new List<PurchaseController.CartItem>();
        cartItems.add(new PurchaseController.CartItem(item.Id, 999, item.Price__c));

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, cartItems);
        Test.stopTest();

        System.assertFalse(result.success);
        System.assert(result.message.contains('Not enough stock'));
    }

    @isTest
    static void testCheckoutNullCart() {
        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, null);
        Test.stopTest();

        System.assertFalse(result.success);
    }

    @isTest
    static void testGetPurchaseById() {
        // Create a purchase for testing
        Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];
        
        PurchaseController.CartItem cartItem = new PurchaseController.CartItem(item.Id, 1, item.Price__c);
        PurchaseController.CheckoutResult checkoutResult = PurchaseController.checkout(accountId, new List<PurchaseController.CartItem>{ cartItem });

        Test.startTest();
        Purchase__c purchase = PurchaseController.getPurchaseById(checkoutResult.purchaseId);
        Test.stopTest();

        System.assertNotEquals(null, purchase);
        System.assertEquals(1, purchase.TotalItems__c);
        System.assert(purchase.Purchase_Lines__r.size() > 0);
    }
}

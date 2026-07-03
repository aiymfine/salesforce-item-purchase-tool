@isTest
public without sharing class PurchaseControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<Item__c> items = new List<Item__c>();
        for (Integer i = 0; i < 3; i++) {
            items.add(new Item__c(
                Type__c = 'Hardware',
                Family__c = 'Electronics',
                Price__c = 10.00 + i * 5,
                AvailableQuantity__c = 10
            ));
        }
        insert items;
    }

    static Id getTestAccountId() {
        return [SELECT Id FROM Account LIMIT 1].Id;
    }

    @isTest
    static void testSuccessfulCheckout() {
        Id accountId = getTestAccountId();
        List<Item__c> items = [SELECT Id, Price__c FROM Item__c LIMIT 2];

        List<PurchaseController.CartItem> cartItems = new List<PurchaseController.CartItem>();
        cartItems.add(new PurchaseController.CartItem(items[0].Id, 2, items[0].Price__c));
        cartItems.add(new PurchaseController.CartItem(items[1].Id, 1, items[1].Price__c));

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, cartItems);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Checkout should succeed: ' + result.message);
        System.assertNotEquals(null, result.purchaseId, 'Purchase ID should not be null');

        Purchase__c purchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :result.purchaseId];
        System.assertEquals(3, purchase.TotalItems__c);
        System.assertEquals(35, purchase.GrandTotal__c);

        List<PurchaseLine__c> lines = [SELECT Amount__c, UnitCost__c FROM PurchaseLine__c WHERE PurchaseId__c = :result.purchaseId];
        System.assertEquals(2, lines.size());

        items = [SELECT Id, AvailableQuantity__c FROM Item__c ORDER BY Name];
        System.assertEquals(8, items[0].AvailableQuantity__c);
        System.assertEquals(9, items[1].AvailableQuantity__c);
        System.assertEquals(10, items[2].AvailableQuantity__c);
    }

    @isTest
    static void testCheckoutEmptyCart() {
        Id accountId = getTestAccountId();

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, new List<PurchaseController.CartItem>());
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals('Cart is empty.', result.message);
    }

    @isTest
    static void testCheckoutInsufficientStock() {
        Id accountId = getTestAccountId();
        Item__c item = [SELECT Id, Price__c, AvailableQuantity__c FROM Item__c LIMIT 1];

        List<PurchaseController.CartItem> cartItems = new List<PurchaseController.CartItem>();
        cartItems.add(new PurchaseController.CartItem(item.Id, 999, item.Price__c));

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, cartItems);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(true, result.message.contains('Not enough stock'));
    }

    @isTest
    static void testCheckoutNullCart() {
        Id accountId = getTestAccountId();

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, null);
        Test.stopTest();

        System.assertEquals(false, result.success);
    }

    @isTest
    static void testGetPurchaseById() {
        Id accountId = getTestAccountId();
        Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];

        PurchaseController.CartItem cartItem = new PurchaseController.CartItem(item.Id, 1, item.Price__c);
        PurchaseController.CheckoutResult checkoutResult = PurchaseController.checkout(accountId, new List<PurchaseController.CartItem>{ cartItem });

        System.assertEquals(true, checkoutResult.success, 'Pre-checkout should succeed: ' + checkoutResult.message);
        System.assertNotEquals(null, checkoutResult.purchaseId, 'Pre-checkout purchaseId should not be null');

        Test.startTest();
        Purchase__c purchase = PurchaseController.getPurchaseById(checkoutResult.purchaseId);
        Test.stopTest();

        System.assertNotEquals(null, purchase);
        System.assertEquals(1, purchase.TotalItems__c);
        System.assertEquals(true, purchase.PurchaseLines__r.size() > 0);
    }
}

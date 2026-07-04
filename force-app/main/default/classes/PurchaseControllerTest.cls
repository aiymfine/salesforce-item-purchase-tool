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

        List<String> itemIds = new List<String>{ String.valueOf(items[0].Id), String.valueOf(items[1].Id) };
        List<Integer> quantities = new List<Integer>{ 2, 1 };
        List<Decimal> unitCosts = new List<Decimal>{ items[0].Price__c, items[1].Price__c };

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, itemIds, quantities, unitCosts);
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
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, new List<String>(), new List<Integer>(), new List<Decimal>());
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals('Cart is empty.', result.message);
    }

    @isTest
    static void testCheckoutNullCart() {
        Id accountId = getTestAccountId();

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, null, null, null);
        Test.stopTest();

        System.assertEquals(false, result.success);
    }

    @isTest
    static void testCheckoutInsufficientStock() {
        Id accountId = getTestAccountId();
        Item__c item = [SELECT Id, Price__c, AvailableQuantity__c FROM Item__c LIMIT 1];

        List<String> itemIds = new List<String>{ String.valueOf(item.Id) };
        List<Integer> quantities = new List<Integer>{ 999 };
        List<Decimal> unitCosts = new List<Decimal>{ item.Price__c };

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, itemIds, quantities, unitCosts);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(true, result.message.contains('Not enough stock'));
    }

    @isTest
    static void testCheckoutInvalidItemId() {
        Id accountId = getTestAccountId();

        List<String> itemIds = new List<String>{ 'invalid-id-123' };
        List<Integer> quantities = new List<Integer>{ 1 };
        List<Decimal> unitCosts = new List<Decimal>{ 10.00 };

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, itemIds, quantities, unitCosts);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(true, result.message.contains('Invalid ID'));
    }

    @isTest
    static void testCheckoutEmptyItemId() {
        Id accountId = getTestAccountId();

        List<String> itemIds = new List<String>{ '' };
        List<Integer> quantities = new List<Integer>{ 1 };
        List<Decimal> unitCosts = new List<Decimal>{ 10.00 };

        Test.startTest();
        PurchaseController.CheckoutResult result = PurchaseController.checkout(accountId, itemIds, quantities, unitCosts);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(true, result.message.contains('Item ID missing'));
    }

    @isTest
    static void testGetPurchaseById() {
        Id accountId = getTestAccountId();
        Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];

        List<String> itemIds = new List<String>{ String.valueOf(item.Id) };
        List<Integer> quantities = new List<Integer>{ 1 };
        List<Decimal> unitCosts = new List<Decimal>{ item.Price__c };

        PurchaseController.CheckoutResult checkoutResult = PurchaseController.checkout(accountId, itemIds, quantities, unitCosts);
        System.assertEquals(true, checkoutResult.success, 'Pre-checkout should succeed: ' + checkoutResult.message);

        Test.startTest();
        Purchase__c purchase = PurchaseController.getPurchaseById(checkoutResult.purchaseId);
        Test.stopTest();

        System.assertNotEquals(null, purchase);
        System.assertEquals(1, purchase.TotalItems__c);
        System.assertEquals(true, purchase.PurchaseLines__r.size() > 0);
    }
}

@isTest
public without sharing class PurchaseLineTriggerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Item__c item1 = new Item__c(
            Type__c = 'Hardware',
            Family__c = 'Electronics',
            Price__c = 25.00,
            AvailableQuantity__c = 10
        );
        Item__c item2 = new Item__c(
            Type__c = 'Software',
            Family__c = 'Software',
            Price__c = 50.00,
            AvailableQuantity__c = 5
        );
        insert new List<Item__c>{ item1, item2 };

        Purchase__c purchase = new Purchase__c(
            ClientId__c = acc.Id,
            TotalItems__c = 0,
            GrandTotal__c = 0
        );
        insert purchase;
    }

    static Purchase__c getTestPurchase() {
        return [SELECT Id FROM Purchase__c LIMIT 1];
    }

    @isTest
    static void testTriggerOnInsert() {
        Purchase__c purchase = getTestPurchase();
        List<Item__c> triggerItems = [SELECT Id FROM Item__c WHERE Type__c IN ('Hardware','Software') LIMIT 2];
        Item__c item1 = triggerItems[0];
        Item__c item2 = triggerItems[1];

        List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
        lines.add(new PurchaseLine__c(
            PurchaseId__c = purchase.Id,
            ItemId__c = item1.Id,
            Amount__c = 3,
            UnitCost__c = 25.00
        ));
        lines.add(new PurchaseLine__c(
            PurchaseId__c = purchase.Id,
            ItemId__c = item2.Id,
            Amount__c = 2,
            UnitCost__c = 50.00
        ));

        Test.startTest();
        insert lines;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(5, updatedPurchase.TotalItems__c, 'Total items should be 5 (3+2)');
        System.assertEquals(175, updatedPurchase.GrandTotal__c, 'Grand total should be 175 (3*25 + 2*50)');
    }

    @isTest
    static void testTriggerOnUpdate() {
        Purchase__c purchase = getTestPurchase();
        Item__c item = [SELECT Id FROM Item__c WHERE Type__c = 'Hardware' LIMIT 1];
        PurchaseLine__c line = new PurchaseLine__c(
            PurchaseId__c = purchase.Id,
            ItemId__c = item.Id,
            Amount__c = 2,
            UnitCost__c = 25.00
        );
        insert line;

        // Requery with only updateable fields to avoid FLS on Master-Detail ItemId__c
        PurchaseLine__c lineToUpdate = new PurchaseLine__c(
            Id = line.Id,
            Amount__c = 5,
            UnitCost__c = 25.00
        );

        Test.startTest();
        update lineToUpdate;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(5, updatedPurchase.TotalItems__c, 'Total items should be 5');
        System.assertEquals(125, updatedPurchase.GrandTotal__c, 'Grand total should be 125 (5*25)');
    }

    @isTest
    static void testTriggerOnDelete() {
        Purchase__c purchase = getTestPurchase();
        Item__c item = [SELECT Id FROM Item__c WHERE Type__c = 'Hardware' LIMIT 1];
        PurchaseLine__c line1 = new PurchaseLine__c(
            PurchaseId__c = purchase.Id,
            ItemId__c = item.Id,
            Amount__c = 2,
            UnitCost__c = 25.00
        );
        PurchaseLine__c line2 = new PurchaseLine__c(
            PurchaseId__c = purchase.Id,
            ItemId__c = item.Id,
            Amount__c = 3,
            UnitCost__c = 25.00
        );
        insert new List<PurchaseLine__c>{ line1, line2 };

        Test.startTest();
        delete line1;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(3, updatedPurchase.TotalItems__c, 'Total items should be 3 after delete');
        System.assertEquals(75, updatedPurchase.GrandTotal__c, 'Grand total should be 75 (3*25)');
    }

    @isTest
    static void testTriggerOnUndelete() {
        Purchase__c purchase = getTestPurchase();
        Item__c item = [SELECT Id FROM Item__c WHERE Type__c = 'Hardware' LIMIT 1];
        PurchaseLine__c line = new PurchaseLine__c(
            PurchaseId__c = purchase.Id,
            ItemId__c = item.Id,
            Amount__c = 4,
            UnitCost__c = 25.00
        );
        insert line;

        Test.startTest();
        delete line;
        undelete line;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(4, updatedPurchase.TotalItems__c, 'Total items should be 4 after undelete');
        System.assertEquals(100, updatedPurchase.GrandTotal__c, 'Grand total should be 100 (4*25)');
    }
}

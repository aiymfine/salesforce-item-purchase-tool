@isTest
public class PurchaseLineTriggerTest {

    static Id purchaseId;

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Item__c item1 = new Item__c(
            Name = 'Trigger Test Item 1',
            Type__c = 'Hardware',
            Family__c = 'Electronics',
            Price__c = 25.00,
            AvailableQuantity__c = 10
        );
        Item__c item2 = new Item__c(
            Name = 'Trigger Test Item 2',
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
        purchaseId = purchase.Id;
    }

    @isTest
    static void testTriggerOnInsert() {
        Item__c item1 = [SELECT Id FROM Item__c WHERE Name = 'Trigger Test Item 1' LIMIT 1];
        Item__c item2 = [SELECT Id FROM Item__c WHERE Name = 'Trigger Test Item 2' LIMIT 1];

        List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
        lines.add(new PurchaseLine__c(
            PurchaseId__c = purchaseId,
            ItemId__c = item1.Id,
            Amount__c = 3,
            UnitCost__c = 25.00
        ));
        lines.add(new PurchaseLine__c(
            PurchaseId__c = purchaseId,
            ItemId__c = item2.Id,
            Amount__c = 2,
            UnitCost__c = 50.00
        ));

        Test.startTest();
        insert lines;
        Test.stopTest();

        Purchase__c purchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(5, purchase.TotalItems__c, 'Total items should be 5 (3+2)');
        System.assertEquals(175, purchase.GrandTotal__c, 'Grand total should be 175 (3*25 + 2*50)');
    }

    @isTest
    static void testTriggerOnUpdate() {
        Item__c item = [SELECT Id FROM Item__c WHERE Name = 'Trigger Test Item 1' LIMIT 1];
        PurchaseLine__c line = new PurchaseLine__c(
            PurchaseId__c = purchaseId,
            ItemId__c = item.Id,
            Amount__c = 2,
            UnitCost__c = 25.00
        );
        insert line;

        line.Amount__c = 5;
        Test.startTest();
        update line;
        Test.stopTest();

        Purchase__c purchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(5, purchase.TotalItems__c, 'Total items should be 5');
        System.assertEquals(125, purchase.GrandTotal__c, 'Grand total should be 125 (5*25)');
    }

    @isTest
    static void testTriggerOnDelete() {
        Item__c item = [SELECT Id FROM Item__c WHERE Name = 'Trigger Test Item 1' LIMIT 1];
        PurchaseLine__c line1 = new PurchaseLine__c(
            PurchaseId__c = purchaseId,
            ItemId__c = item.Id,
            Amount__c = 2,
            UnitCost__c = 25.00
        );
        PurchaseLine__c line2 = new PurchaseLine__c(
            PurchaseId__c = purchaseId,
            ItemId__c = item.Id,
            Amount__c = 3,
            UnitCost__c = 25.00
        );
        insert new List<PurchaseLine__c>{ line1, line2 };

        Test.startTest();
        delete line1;
        Test.stopTest();

        Purchase__c purchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(3, purchase.TotalItems__c, 'Total items should be 3 after delete');
        System.assertEquals(75, purchase.GrandTotal__c, 'Grand total should be 75 (3*25)');
    }

    @isTest
    static void testTriggerOnUndelete() {
        Item__c item = [SELECT Id FROM Item__c WHERE Name = 'Trigger Test Item 1' LIMIT 1];
        PurchaseLine__c line = new PurchaseLine__c(
            PurchaseId__c = purchaseId,
            ItemId__c = item.Id,
            Amount__c = 4,
            UnitCost__c = 25.00
        );
        insert line;

        Test.startTest();
        delete line;
        undelete line;
        Test.stopTest();

        Purchase__c purchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(4, purchase.TotalItems__c, 'Total items should be 4 after undelete');
        System.assertEquals(100, purchase.GrandTotal__c, 'Grand total should be 100 (4*25)');
    }
}

@isTest
public without sharing class ItemControllerTest {

    @TestSetup
    static void setup() {
        List<Item__c> items = new List<Item__c>();
        for (Integer i = 0; i < 5; i++) {
            items.add(new Item__c(
                Description__c = 'Description for item ' + i,
                Type__c = 'Hardware',
                Family__c = 'Electronics',
                Price__c = 10.00 + i * 5,
                AvailableQuantity__c = 10 + i
            ));
        }
        insert items;
    }

    @isTest
    static void testGetItems() {
        List<Item__c> items = ItemController.getItems();
        System.assertEquals(5, items.size());
    }

    @isTest
    static void testGetItemsByFilterFamily() {
        List<Item__c> items = ItemController.getItemsByFilter('Electronics', '', '');
        System.assertEquals(5, items.size());
    }

    @isTest
    static void testGetItemsByFilterType() {
        List<Item__c> items = ItemController.getItemsByFilter('', 'Hardware', '');
        System.assertEquals(5, items.size());
    }

    @isTest
    static void testGetItemsByFilterSearch() {
        List<Item__c> items = ItemController.getItemsByFilter('', '', 'Description for item 2');
        System.assertEquals(1, items.size());
    }

    @isTest
    static void testGetItemsByFilterCombined() {
        List<Item__c> items = ItemController.getItemsByFilter('Electronics', 'Hardware', 'Description');
        System.assertEquals(5, items.size());
    }

    @isTest
    static void testGetItemsByFilterNoResults() {
        List<Item__c> items = ItemController.getItemsByFilter('Software', 'Service', '');
        System.assertEquals(0, items.size());
    }

    @isTest
    static void testGetItemById() {
        Item__c item = [SELECT Id FROM Item__c LIMIT 1];
        Item__c result = ItemController.getItemById(item.Id);
        System.assertNotEquals(null, result);
        System.assertEquals(item.Id, result.Id);
    }

    @isTest
    static void testCreateItem() {
        Item__c newItem = new Item__c(
            Description__c = 'New item desc',
            Type__c = 'Software',
            Family__c = 'Software',
            Price__c = 99.99,
            AvailableQuantity__c = 50
        );
        Test.startTest();
        Item__c created = ItemController.createItem(newItem);
        Test.stopTest();

        System.assertNotEquals(null, created, 'createItem should return the created item');
        System.assertNotEquals(null, created.Id, 'Created item should have an Id');
    }

    @isTest
    static void testCreateItemWithNullQuantity() {
        Item__c newItem = new Item__c(
            Price__c = 5.00
        );
        Test.startTest();
        Item__c created = ItemController.createItem(newItem);
        Test.stopTest();

        System.assertEquals(0, created.AvailableQuantity__c);
    }

    @isTest
    static void testGetAvailableItems() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Test.startTest();
        List<Item__c> items = ItemController.getAvailableItems(acc.Id);
        Test.stopTest();

        System.assertEquals(5, items.size());
    }

    @isTest
    static void testGetItemFamilies() {
        List<String> families = ItemController.getItemFamilies();
        System.assert(families.size() > 0);
        System.assert(families.contains('Electronics'));
    }

    @isTest
    static void testGetItemTypes() {
        List<String> types = ItemController.getItemTypes();
        System.assert(types.size() > 0);
        System.assert(types.contains('Hardware'));
    }
}

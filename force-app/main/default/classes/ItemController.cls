public with sharing class ItemController {
    
    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems() {
        return [
            SELECT Id, Name, Description__c, Type__c, Family__c, 
                   Image__c, Price__c, AvailableQuantity__c
            FROM Item__c
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItemsByFilter(String family, String type, String searchKey) {
        String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, AvailableQuantity__c FROM Item__c WHERE ';
        List<String> conditions = new List<String>();

        if (String.isNotBlank(family)) {
            conditions.add('Family__c = :family');
        }
        if (String.isNotBlank(type)) {
            conditions.add('Type__c = :type');
        }
        if (String.isNotBlank(searchKey)) {
            String likeKey = '%' + searchKey + '%';
            conditions.add('(Name LIKE :likeKey OR Description__c LIKE :likeKey)');
        }

        if (conditions.isEmpty()) {
            query += 'Id != null';
        } else {
            query += String.join(conditions, ' AND ');
        }

        query += ' ORDER BY Name ASC LIMIT 100';

        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static Item__c getItemById(Id itemId) {
        return [
            SELECT Id, Name, Description__c, Type__c, Family__c, 
                   Image__c, Price__c, AvailableQuantity__c
            FROM Item__c
            WHERE Id = :itemId
        ];
    }

    @AuraEnabled
    public static Item__c createItem(Item__c item) {
        if (item.AvailableQuantity__c == null) {
            item.AvailableQuantity__c = 0;
        }
        insert item;
        return item;
    }

    @AuraEnabled
    public static List<Item__c> getItemsWithQuantity(Id recordId) {
        List<Item__c> items = new List<Item__c>();
        for (Item__c item : [
            SELECT Id, Name, Description__c, Type__c, Family__c, 
                   Image__c, Price__c, AvailableQuantity__c
            FROM Item__c
            WHERE AvailableQuantity__c > 0
            ORDER BY Name ASC
        ]) {
            items.add(item);
        }
        return items;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getItemFamilies() {
        List<String> families = new List<String>();
        Schema.DescribeFieldResult field = Item__c.Family__c.getDescribe();
        for (Schema.PicklistEntry entry : field.getPicklistValues()) {
            families.add(entry.getValue());
        }
        return families;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getItemTypes() {
        List<String> types = new List<String>();
        Schema.DescribeFieldResult field = Item__c.Type__c.getDescribe();
        for (Schema.PicklistEntry entry : field.getPicklistValues()) {
            types.add(entry.getValue());
        }
        return types;
    }
}

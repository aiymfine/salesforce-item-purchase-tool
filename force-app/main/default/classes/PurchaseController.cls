public with sharing class PurchaseController {

    public class CheckoutResult {
        @AuraEnabled public Id purchaseId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;

        public CheckoutResult(Id purchaseId, Boolean success, String message) {
            this.purchaseId = purchaseId;
            this.success = success;
            this.message = message;
        }
    }

    @AuraEnabled
    public static CheckoutResult checkout(Id accountId, List<String> itemIds, List<Integer> quantities, List<Decimal> unitCosts) {
        CheckoutResult result = new CheckoutResult(null, false, '');

        if (itemIds == null || itemIds.isEmpty()) {
            result.message = 'Cart is empty.';
            return result;
        }
        if (quantities == null || unitCosts == null) {
            result.message = 'Missing quantities or costs data.';
            return result;
        }
        if (quantities.size() != itemIds.size()) {
            result.message = 'Mismatched quantities array.';
            return result;
        }
        if (unitCosts.size() != itemIds.size()) {
            result.message = 'Mismatched costs array.';
            return result;
        }

        System.debug('DEBUG checkout: accountId=' + accountId + ' itemIds.size=' + itemIds.size());

        // Validate and collect IDs
        Set<Id> validIds = new Set<Id>();
        for (Integer i = 0; i < itemIds.size(); i++) {
            String rawId = itemIds[i];
            System.debug('DEBUG item[' + i + ']: rawId=' + rawId + ' qty=' + quantities[i] + ' cost=' + unitCosts[i]);
            if (String.isBlank(rawId)) {
                result.message = 'Item ID missing at position ' + (i + 1);
                return result;
            }
            try {
                validIds.add(Id.valueOf(rawId));
            } catch (Exception e) {
                result.message = 'Invalid ID at position ' + (i + 1) + ': ' + rawId;
                return result;
            }
        }

        Map<Id, Item__c> itemMap = new Map<Id, Item__c>([
            SELECT Id, Name, AvailableQuantity__c, Price__c
            FROM Item__c
            WHERE Id IN :validIds
        ]);

        // Validate stock
        for (Integer i = 0; i < itemIds.size(); i++) {
            Id parsedId = Id.valueOf(itemIds[i]);
            Item__c item = itemMap.get(parsedId);
            if (item == null) {
                result.message = 'Item not found: ' + itemIds[i];
                return result;
            }
            if (item.AvailableQuantity__c < quantities[i]) {
                result.message = 'Not enough stock for ' + item.Name + '. Available: ' + item.AvailableQuantity__c + ', Requested: ' + quantities[i];
                return result;
            }
        }

        // Create Purchase
        Purchase__c purchase = new Purchase__c();
        purchase.ClientId__c = accountId;
        purchase.TotalItems__c = 0;
        purchase.GrandTotal__c = 0;

        try {
            insert purchase;
        } catch (Exception e) {
            result.message = 'Failed to create purchase: ' + e.getMessage();
            return result;
        }

        // Create Purchase Lines and update stock
        List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
        List<Item__c> itemsToUpdate = new List<Item__c>();
        Decimal grandTotal = 0;
        Integer totalItems = 0;

        for (Integer i = 0; i < itemIds.size(); i++) {
            Id parsedId = Id.valueOf(itemIds[i]);
            Item__c item = itemMap.get(parsedId);

            PurchaseLine__c line = new PurchaseLine__c();
            line.PurchaseId__c = purchase.Id;
            line.ItemId__c = parsedId;
            line.Amount__c = quantities[i];
            line.UnitCost__c = unitCosts[i];
            lines.add(line);

            Item__c itemToUpdate = new Item__c(Id = item.Id);
            itemToUpdate.AvailableQuantity__c = item.AvailableQuantity__c - quantities[i];
            itemsToUpdate.add(itemToUpdate);

            grandTotal += unitCosts[i] * quantities[i];
            totalItems += quantities[i];
        }

        try {
            insert lines;
            update itemsToUpdate;
        } catch (Exception e) {
            result.message = 'Failed to create purchase lines: ' + e.getMessage();
            return result;
        }

        result.purchaseId = purchase.Id;
        result.success = true;
        result.message = 'Purchase created successfully!';
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Purchase__c getPurchaseById(Id purchaseId) {
        return [
            SELECT Id, Name, ClientId__c, ClientId__r.Name, TotalItems__c, GrandTotal__c,
                   (SELECT Id, Name, ItemId__c, ItemId__r.Name, Amount__c, UnitCost__c 
                    FROM PurchaseLines__r)
            FROM Purchase__c
            WHERE Id = :purchaseId
        ];
    }
}

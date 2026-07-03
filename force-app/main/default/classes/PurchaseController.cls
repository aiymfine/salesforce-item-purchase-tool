public with sharing class PurchaseController {

    public class CartItem {
        @AuraEnabled public Id itemId;
        @AuraEnabled public Integer quantity;
        @AuraEnabled public Decimal unitCost;

        public CartItem(Id itemId, Integer quantity, Decimal unitCost) {
            this.itemId = itemId;
            this.quantity = quantity;
            this.unitCost = unitCost;
        }
    }

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
    public static CheckoutResult checkout(Id accountId, List<CartItem> cartItems) {
        CheckoutResult result = new CheckoutResult(null, false, '');

        if (cartItems == null || cartItems.isEmpty()) {
            result.message = 'Cart is empty.';
            return result;
        }

        // Validate stock availability for all items
        Set<Id> itemIds = new Set<Id>();
        for (CartItem ci : cartItems) {
            itemIds.add(ci.itemId);
        }

        Map<Id, Item__c> itemMap = new Map<Id, Item__c>([
            SELECT Id, Name, AvailableQuantity__c, Price__c
            FROM Item__c
            WHERE Id IN :itemIds
        ]);

        for (CartItem ci : cartItems) {
            Item__c item = itemMap.get(ci.itemId);
            if (item == null) {
                result.message = 'Item not found: ' + ci.itemId;
                return result;
            }
            if (item.AvailableQuantity__c < ci.quantity) {
                result.message = 'Not enough stock for ' + item.Name + '. Available: ' + item.AvailableQuantity__c + ', Requested: ' + ci.quantity;
                return result;
            }
        }

        // Create Purchase record
        Purchase__c purchase = new Purchase__c();
        purchase.ClientId__c = accountId;
        purchase.TotalItems__c = 0;
        purchase.GrandTotal__c = 0;

        try {
            insert purchase;
        } catch (DmlException e) {
            result.message = 'Failed to create purchase: ' + e.getMessage();
            return result;
        }

        // Create Purchase Lines and update stock
        List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
        List<Item__c> itemsToUpdate = new List<Item__c>();
        Decimal grandTotal = 0;
        Integer totalItems = 0;

        for (CartItem ci : cartItems) {
            Item__c item = itemMap.get(ci.itemId);

            PurchaseLine__c line = new PurchaseLine__c();
            line.PurchaseId__c = purchase.Id;
            line.ItemId__c = ci.itemId;
            line.Amount__c = ci.quantity;
            line.UnitCost__c = ci.unitCost;
            lines.add(line);

            // Prepare stock update
            Item__c itemToUpdate = new Item__c(Id = item.Id);
            itemToUpdate.AvailableQuantity__c = item.AvailableQuantity__c - ci.quantity;
            itemsToUpdate.add(itemToUpdate);

            grandTotal += ci.unitCost * ci.quantity;
            totalItems += ci.quantity;
        }

        try {
            insert lines;
            update itemsToUpdate;
        } catch (DmlException e) {
            // Clean up purchase if lines fail
            delete [SELECT Id FROM PurchaseLine__c WHERE PurchaseId__c = :purchase.Id];
            delete [SELECT Id FROM Purchase__c WHERE Id = :purchase.Id];
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

trigger PurchaseLineTrigger on PurchaseLine__c (after insert, after update, after delete, after undelete) {
    Set<Id> purchaseIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (PurchaseLine__c pl : Trigger.new) {
            purchaseIds.add(pl.PurchaseId__c);
        }
    }

    if (Trigger.isDelete) {
        for (PurchaseLine__c pl : Trigger.old) {
            purchaseIds.add(pl.PurchaseId__c);
        }
    }

    if (purchaseIds.isEmpty()) return;

    // Aggregate totals per Purchase
    List<Purchase__c> purchasesToUpdate = new List<Purchase__c>();

    for (AggregateResult ar : [
        SELECT PurchaseId__c, SUM(Amount__c) totalItems, SUM(UnitCost__c * Amount__c) grandTotal
        FROM PurchaseLine__c
        WHERE PurchaseId__c IN :purchaseIds
        GROUP BY PurchaseId__c
    ]) {
        purchasesToUpdate.add(new Purchase__c(
            Id = (Id) ar.get('PurchaseId__c'),
            TotalItems__c = (Decimal) ar.get('totalItems'),
            GrandTotal__c = (Decimal) ar.get('grandTotal')
        ));
    }

    if (!purchasesToUpdate.isEmpty()) {
        update purchasesToUpdate;
    }
}

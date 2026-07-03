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

    // Calculate totals from individual records instead of using aggregate on formula field
    List<PurchaseLine__c> allLines = [
        SELECT PurchaseId__c, Amount__c, UnitCost__c
        FROM PurchaseLine__c
        WHERE PurchaseId__c IN :purchaseIds
    ];

    Map<Id, Purchase__c> purchasesToUpdate = new Map<Id, Purchase__c>();
    for (PurchaseLine__c pl : allLines) {
        Purchase__c p = purchasesToUpdate.get(pl.PurchaseId__c);
        if (p == null) {
            p = new Purchase__c(
                Id = pl.PurchaseId__c,
                TotalItems__c = 0,
                GrandTotal__c = 0
            );
            purchasesToUpdate.put(pl.PurchaseId__c, p);
        }
        p.TotalItems__c += pl.Amount__c;
        p.GrandTotal__c += pl.UnitCost__c * pl.Amount__c;
    }

    if (!purchasesToUpdate.isEmpty()) {
        update purchasesToUpdate.values();
    }
}

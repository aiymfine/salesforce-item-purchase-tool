import { LightningElement, api } from 'lwc';

export default class ItemPurchaseToolItem extends LightningElement {
    @api item;

    get isOutOfStock() {
        return !this.item || this.item.AvailableQuantity__c <= 0;
    }

    get itemImage() {
        return this.item?.Image__c || '';
    }

    get hasImage() {
        return !!this.item?.Image__c;
    }

    handleDetails() {
        this.dispatchEvent(new CustomEvent('showdetail', {
            detail: this.item.Id
        }));
    }

    handleAdd() {
        if (this.isOutOfStock) return;
        this.dispatchEvent(new CustomEvent('addtocart', {
            detail: this.item.Id
        }));
    }
}

import { LightningElement, api } from 'lwc';

export default class ItemDetailModal extends LightningElement {
    @api item;

    get isOutOfStock() {
        return !this.item || this.item.AvailableQuantity__c <= 0;
    }

    get hasImage() {
        return !!this.item?.Image__c;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closedetail'));
    }

    handleAdd() {
        const itemId = this.item.Id || this.item.id;
        if (itemId) {
            this.dispatchEvent(new CustomEvent('addtocart', {
                detail: String(itemId)
            }));
        }
    }
}

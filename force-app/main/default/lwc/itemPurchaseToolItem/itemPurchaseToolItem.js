import { LightningElement, api, track } from 'lwc';

export default class ItemPurchaseToolItem extends LightningElement {
    @api item;

    @track imageFailed = false;

    get isOutOfStock() {
        return !this.item || this.item.AvailableQuantity__c <= 0;
    }

    get itemImage() {
        return this.item?.Image__c || '';
    }

    get hasImage() {
        return !!this.item?.Image__c && !this.imageFailed;
    }

    handleImageError() {
        this.imageFailed = true;
    }

    _getItemId() {
        const el = this.template.querySelector('[data-item-id]');
        return el ? el.dataset.itemId : null;
    }

    handleDetails() {
        const itemId = this._getItemId();
        if (itemId) {
            this.dispatchEvent(new CustomEvent('showdetail', {
                detail: itemId,
                bubbles: false,
                composed: false
            }));
        }
    }

    handleAdd() {
        if (this.isOutOfStock) return;
        const itemId = this._getItemId();
        if (!itemId) return;
        this.dispatchEvent(new CustomEvent('addtocart', {
            detail: itemId,
            bubbles: false,
            composed: false
        }));
    }
}

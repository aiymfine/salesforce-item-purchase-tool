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
        // querySelector reads data-attr from native div — bypasses lightning-button shadow DOM
        const el = this.template.querySelector('[data-item-id]');
        return el ? el.dataset.itemId : null;
    }

    handleDetails() {
        const itemId = this._getItemId();
        console.log('handleDetails: itemId =', itemId);
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
        console.log('handleAdd: itemId =', itemId, 'item.Id =', this.item?.Id, 'item.id =', this.item?.id);
        if (!itemId) {
            console.error('handleAdd: FAILED to get itemId!', JSON.stringify(this.item));
            return;
        }
        this.dispatchEvent(new CustomEvent('addtocart', {
            detail: itemId,
            bubbles: false,
            composed: false
        }));
    }
}

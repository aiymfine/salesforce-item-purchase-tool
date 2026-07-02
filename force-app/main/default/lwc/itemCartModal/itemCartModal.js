import { LightningElement, api } from 'lwc';

export default class ItemCartModal extends LightningElement {
    @api cart = [];
    @api cartTotal = 0;
    @api cartItemCount = 0;
    @api isLoading = false;

    get hasItems() {
        return this.cart.length > 0;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closecart'));
    }

    handleCheckout() {
        this.dispatchEvent(new CustomEvent('checkout'));
    }

    handleQuantityChange(event) {
        const itemId = event.target.dataset.itemId;
        const newQuantity = parseInt(event.target.value, 10) || 1;
        this.dispatchEvent(new CustomEvent('updatequantity', {
            detail: { itemId, newQuantity }
        }));
    }

    handleRemove(event) {
        const itemId = event.target.dataset.itemId;
        this.dispatchEvent(new CustomEvent('removefromcart', {
            detail: itemId
        }));
    }

    handleQuantityBlur(event) {
        let val = parseInt(event.target.value, 10);
        if (isNaN(val) || val < 1) val = 1;
        event.target.value = val;
    }
}

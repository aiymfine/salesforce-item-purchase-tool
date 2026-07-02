import { LightningElement, api, track } from 'lwc';

export default class ItemCartModal extends LightningElement {
    @api cart;
    @api cartTotal;
    @api cartItemCount;
    @api isLoading;

    get hasItems() {
        return this.cart && this.cart.length > 0;
    }

    get isCheckoutDisabled() {
        return !this.hasItems || this.isLoading;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closecart'));
    }

    handleQuantityChange(event) {
        const itemId = event.target.dataset.itemId;
        const newQuantity = parseInt(event.target.value, 10);
        this.dispatchEvent(new CustomEvent('updatequantity', {
            detail: { itemId, newQuantity }
        }));
    }

    handleQuantityBlur(event) {
        const itemId = event.target.dataset.itemId;
        const newQuantity = parseInt(event.target.value, 10);
        if (isNaN(newQuantity) || newQuantity < 1) {
            event.target.value = 1;
            this.dispatchEvent(new CustomEvent('updatequantity', {
                detail: { itemId, newQuantity: 1 }
            }));
        }
    }

    handleRemove(event) {
        const itemId = event.currentTarget.dataset.itemId;
        this.dispatchEvent(new CustomEvent('removefromcart', {
            detail: itemId
        }));
    }

    handleCheckout() {
        if (this.isCheckoutDisabled) return;
        this.dispatchEvent(new CustomEvent('checkout'));
    }

    getItemSubtotal(cartItem) {
        return cartItem.item.Price__c * cartItem.quantity;
    }
}

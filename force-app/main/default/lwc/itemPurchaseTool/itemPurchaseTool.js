import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isCurrentUserManager from '@salesforce/apex/UserController.isCurrentUserManager';
import getItemFamilies from '@salesforce/apex/ItemController.getItemFamilies';
import getItemTypes from '@salesforce/apex/ItemController.getItemTypes';
import getAvailableItems from '@salesforce/apex/ItemController.getAvailableItems';
import checkout from '@salesforce/apex/PurchaseController.checkout';

const ACCOUNT_FIELDS = [
    'Account.Name',
    'Account.AccountNumber',
    'Account.Industry'
];

export default class ItemPurchaseTool extends NavigationMixin(LightningElement) {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    accountRecord;

    get accountName() {
        return getFieldValue(this.accountRecord.data, 'Account.Name') || '';
    }
    get accountNumber() {
        return getFieldValue(this.accountRecord.data, 'Account.AccountNumber') || '';
    }
    get accountIndustry() {
        return getFieldValue(this.accountRecord.data, 'Account.Industry') || '';
    }

    @wire(getItemFamilies)
    familiesWire(result) {
        this._familiesResult = result;
        if (result.data) {
            this._familyOptions = result.data.map(f => ({ label: f, value: f }));
        }
    }

    @wire(getItemTypes)
    typesWire(result) {
        this._typesResult = result;
        if (result.data) {
            this._typeOptions = result.data.map(t => ({ label: t, value: t }));
        }
    }

    @wire(getAvailableItems, { recordId: '$recordId' })
    itemsWire(result) {
        this._itemsResult = result;
        if (result.data) {
            this.items = result.data;
            this.applyFilters();
        }
    }

    @wire(isCurrentUserManager)
    isManagerWire(result) {
        if (result.data) {
            this.isManager = result.data;
        }
    }

    // Reactive state
    items = [];
    filteredItems = [];
    cart = [];
    selectedFamily = '';
    selectedType = '';
    searchKey = '';
    showCartModal = false;
    showDetailModal = false;
    showCreateModal = false;
    selectedItem = null;
    isManager = false;
    isLoading = false;

    // Wire result references for refresh
    _itemsResult;
    _familiesResult;
    _typesResult;
    _familyOptions = [];
    _typeOptions = [];

    // Getters for template bindings
    get familyOptions() { return this._familyOptions; }
    get typeOptions() { return this._typeOptions; }

    get itemCount() {
        return this.filteredItems.length;
    }

    get cartItemCount() {
        return this.cart.reduce((sum, ci) => sum + ci.quantity, 0);
    }

    get cartTotal() {
        return this.cart.reduce((sum, ci) => sum + (ci.unitPrice * ci.quantity), 0);
    }

    get isCartEmpty() {
        return this.cartItemCount === 0;
    }

    get hasItems() {
        return this.filteredItems.length > 0;
    }

    handleFamilyChange(event) {
        this.selectedFamily = event.detail.value;
        this.applyFilters();
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.applyFilters();
    }

    handleSearchChange(event) {
        this.searchKey = event.detail.value.toLowerCase();
        this.applyFilters();
    }

    applyFilters() {
        let filtered = [...this.items];

        if (this.selectedFamily) {
            filtered = filtered.filter(i => i.Family__c === this.selectedFamily);
        }
        if (this.selectedType) {
            filtered = filtered.filter(i => i.Type__c === this.selectedType);
        }
        if (this.searchKey) {
            filtered = filtered.filter(i =>
                (i.Name && i.Name.toLowerCase().includes(this.searchKey)) ||
                (i.Description__c && i.Description__c.toLowerCase().includes(this.searchKey))
            );
        }

        this.filteredItems = filtered;
    }

    _getItemId(item) {
        return item.Id || item.id;
    }

    handleShowDetail(event) {
        const itemId = event.detail;
        this.selectedItem = this.items.find(i => this._getItemId(i) === itemId);
        this.showDetailModal = true;
    }

    handleCloseDetail() {
        this.showDetailModal = false;
        this.selectedItem = null;
    }

    handleShowCart() {
        this.showCartModal = true;
    }

    handleCloseCart() {
        this.showCartModal = false;
    }

    handleShowCreate() {
        this.showCreateModal = true;
    }

    handleCloseCreate() {
        this.showCreateModal = false;
    }

    handleItemCreated() {
        this.showCreateModal = false;
        refreshApex(this._itemsResult);
    }

    handleAddToCart(event) {
        const itemId = event.detail;
        if (!itemId) {
            console.error('handleAddToCart: itemId is empty!', event.detail);
            this.showToast('Error', 'Could not identify item.', 'error');
            return;
        }
        console.log('handleAddToCart: itemId =', itemId, typeof itemId);
        const item = this.items.find(i => this._getItemId(i) === itemId);
        if (!item || item.AvailableQuantity__c <= 0) {
            this.showToast('Out of Stock', 'This item is no longer available.', 'warning');
            return;
        }

        const existing = this.cart.find(c => c.itemId === itemId);
        if (existing) {
            if (existing.quantity < item.AvailableQuantity__c) {
                existing.quantity++;
                this.cart = [...this.cart];
            } else {
                this.showToast('Max Stock', 'Cannot add more of this item.', 'warning');
            }
        } else {
            this.cart = [...this.cart, {
                itemId: String(itemId),
                itemName: item.Name,
                unitPrice: item.Price__c,
                maxQty: item.AvailableQuantity__c,
                quantity: 1
            }];
        }

        console.log('Cart after add:', JSON.parse(JSON.stringify(this.cart)));
        this.showToast('Added', item.Name + ' added to cart.', 'success');
    }

    handleUpdateCartQuantity(event) {
        const { itemId, newQuantity } = event.detail;
        this.cart = this.cart.map(c =>
            c.itemId === itemId ? { ...c, quantity: newQuantity } : c
        );
    }

    handleRemoveFromCart(event) {
        const itemId = event.detail;
        this.cart = this.cart.filter(c => c.itemId !== itemId);
    }

    handleCheckout() {
        this.isLoading = true;
        const itemIds = this.cart.map(c => c.itemId);
        const quantities = this.cart.map(c => c.quantity);
        const unitCosts = this.cart.map(c => c.unitPrice);
        console.log('CHECKOUT: itemIds=' + JSON.stringify(itemIds));

        checkout({ accountId: this.recordId, itemIds, quantities, unitCosts })
            .then(result => {
                if (result.success) {
                    this.showToast('Success', 'Purchase created! (ID: ' + result.purchaseId + ')', 'success');
                    this.cart = [];
                    this.showCartModal = false;

                    try {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: result.purchaseId,
                                objectApiName: 'Purchase__c',
                                actionName: 'view'
                            }
                        });
                    } catch (navError) {
                        // Navigation may fail if user lacks tab access
                    }
                } else {
                    this.showToast('Checkout Failed', result.message, 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(evt);
    }
}

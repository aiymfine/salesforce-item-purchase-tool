import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createItem from '@salesforce/apex/ItemController.createItem';
import searchUnsplashImage from '@salesforce/apex/UnsplashController.searchImage';

export default class CreateItemModal extends LightningElement {
    @track newItem = {
        Name: '',
        Description__c: '',
        Type__c: '',
        Family__c: '',
        Price__c: 0,
        AvailableQuantity__c: 0,
        Image__c: ''
    };
    @track isSaving = false;
    @track isSearchingImage = false;

    handleClose() {
        this.dispatchEvent(new CustomEvent('closecreate'));
    }

    handleImageUrlChange(event) {
        this.newItem.Image__c = event.target.value;
    }

    async handleSearchImage() {
        const nameInput = this.template.querySelector('lightning-input-field[field-name="Name"]');
        const itemName = nameInput ? nameInput.value : '';
        
        if (!itemName) {
            this.showToast('Error', 'Enter item name first to search for an image.', 'error');
            return;
        }

        this.isSearchingImage = true;
        try {
            const imageUrl = await searchUnsplashImage({ query: itemName });
            if (imageUrl) {
                this.newItem.Image__c = imageUrl;
                this.showToast('Found', 'Image found and set!', 'success');
            } else {
                this.showToast('Not Found', 'No image found for "' + itemName + '".', 'warning');
            }
        } catch (error) {
            this.showToast('Error', 'Image search failed: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isSearchingImage = false;
        }
    }

    handleSave() {
        const inputs = this.template.querySelectorAll('lightning-input-field');
        const itemData = {};

        inputs.forEach(input => {
            if (input.fieldName) {
                itemData[input.fieldName] = input.value;
            }
        });

        if (!itemData.Name || itemData.Name.trim() === '') {
            this.showToast('Error', 'Item Name is required.', 'error');
            return;
        }

        const newItem = {
            ...itemData,
            Image__c: this.newItem.Image__c || null,
            Price__c: itemData.Price__c || 0,
            AvailableQuantity__c: itemData.AvailableQuantity__c || 0
        };

        this.isSaving = true;
        createItem({ item: newItem })
            .then(result => {
                this.showToast('Success', 'Item "' + result.Name + '" created successfully!', 'success');
                this.dispatchEvent(new CustomEvent('itemcreated'));
            })
            .catch(error => {
                this.showToast('Error', 'Failed to create item: ' + (error.body?.message || error.message), 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(evt);
    }
}

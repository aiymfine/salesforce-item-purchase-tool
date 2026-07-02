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

    typeOptions = [
        { label: 'Software', value: 'Software' },
        { label: 'Hardware', value: 'Hardware' },
        { label: 'Service', value: 'Service' },
        { label: 'Accessory', value: 'Accessory' },
        { label: 'Other', value: 'Other' }
    ];

    familyOptions = [
        { label: 'Electronics', value: 'Electronics' },
        { label: 'Office', value: 'Office' },
        { label: 'Peripherals', value: 'Peripherals' },
        { label: 'Software', value: 'Software' },
        { label: 'Other', value: 'Other' }
    ];

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'number' ? parseFloat(event.target.value) || 0 : event.target.value;
        this.newItem = { ...this.newItem, [field]: value };
    }

    handleTypeChange(event) {
        this.newItem.Type__c = event.detail.value;
    }

    handleFamilyChange(event) {
        this.newItem.Family__c = event.detail.value;
    }

    handleImageUrlChange(event) {
        this.newItem.Image__c = event.target.value;
    }

    async handleSearchImage() {
        if (!this.newItem.Name) {
            this.showToast('Error', 'Enter item name first to search for an image.', 'error');
            return;
        }

        this.isSearchingImage = true;
        try {
            const imageUrl = await searchUnsplashImage({ query: this.newItem.Name });
            if (imageUrl) {
                this.newItem.Image__c = imageUrl;
                this.showToast('Found', 'Image found and set!', 'success');
            } else {
                this.showToast('Not Found', 'No image found for "' + this.newItem.Name + '".', 'warning');
            }
        } catch (error) {
            this.showToast('Error', 'Image search failed: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isSearchingImage = false;
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closecreate'));
    }

    handleSave() {
        // Validation
        if (!this.newItem.Name || this.newItem.Name.trim() === '') {
            this.showToast('Error', 'Item Name is required.', 'error');
            return;
        }
        if (this.newItem.Price__c <= 0) {
            this.showToast('Error', 'Price must be greater than 0.', 'error');
            return;
        }

        this.isSaving = true;
        createItem({ item: this.newItem })
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

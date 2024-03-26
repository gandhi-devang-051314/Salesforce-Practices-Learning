import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LwcFromFlow extends LightningElement {
    @api recordId;
    @api records = [];
    @api fieldColumns = [
        // { label: 'Id', fieldName: 'Id'},
        { label: 'Product Name', fieldName: 'SBQQ__ProductName__c' },
        { label: 'Quantity', fieldName: 'SBQQ__Quantity__c' },
        { label: 'List Unit Price', fieldName: 'SBQQ__ListPrice__c', type: 'currency' },
        { label: 'Upload', type: 'fileUpload', fieldName: 'Id', typeAttributes: { acceptedFormats: '.jpg,.jpeg,.pdf,.png' } }
    ];

    connectedCallback(){
        // console.log(this.recordId);
        // console.log(JSON.stringify(this.records));
    }

    handleUploadFinished(event) {
        event.stopPropagation();
        console.log('data => ', JSON.stringify(event.detail.data));
    }

    handleFileDelete(event){
        event.stopPropagation();
        console.log('data => ', JSON.stringify(event.detail.data));
        this.showToast(event.detail.data.title, event.detail.data.message, event.detail.data.variant);
    }

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
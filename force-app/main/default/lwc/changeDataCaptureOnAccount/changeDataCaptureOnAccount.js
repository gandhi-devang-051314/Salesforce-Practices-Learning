import { LightningElement, api } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';

export default class ChangeDataCaptureOnAccount extends LightningElement {
    @api recordId;
    @api channelName = '/data/AccountChangeEvent';
    subscription = {};

    connectedCallback() {
        // console.log(`I'm here!`);
        this.registerErrorListener();
        this.handleSubscribe();
    }

    registerErrorListener() {
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
        });
    }

    handleSubscribe() {
        const messageCallback = (response)=> {
            this.handleEvent(response);
        };

        subscribe(this.channelName, -1, messageCallback).then((response) => {
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }

    async handleEvent(res){

        if(res && res.data && res.data.payload){
            if(this.recordId == res.data.payload.ChangeEventHeader.recordIds[0]){
                const changedFields = res.data.payload.ChangeEventHeader.changedFields.join(',');
                this.showToast('Record updated!', `${changedFields} fields has been updated!`, 'success');
                await notifyRecordUpdateAvailable([{recordId: this.recordId}]); 
            }
        }
        else{
            console.log('Something went wrong!', JSON.stringify(res));
        }
    }

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
              title,
              message,
              variant,
            })
        );
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }

}
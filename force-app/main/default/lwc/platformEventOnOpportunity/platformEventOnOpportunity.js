import { LightningElement, api } from 'lwc';
import { updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';

import ID_FLD from '@salesforce/schema/Opportunity.Id';
import STAGE_FLD from '@salesforce/schema/Opportunity.StageName';

export default class PlatformEventOnOpportunity extends LightningElement {
    @api recordId;
    channelName = '/event/TestOppEvent__e';
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

    handleEvent(res){
        //console.log('Response From Event', JSON.stringify(res));
        if(res && res.data && res.data.payload){
            const fields = {};
            fields[ID_FLD.fieldApiName] = res.data.payload.Id__c;
            fields[STAGE_FLD.fieldApiName] = res.data.payload.StageName__c;

            updateRecord({fields})
            .then(async ()=>{
                if(this.recordId == res.data.payload.Id__c){
                    this.showToast('Record update success!', 'Successfully updating record via plateform event', 'success');
                    await notifyRecordUpdateAvailable([{recordId: this.recordId}]);
                }
            })
            .catch(err=>{
                console.log(`Error while updating values`, err);
                this.showToast('Error updating record!', err, 'error');
            });
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
            }),
        );
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }
}
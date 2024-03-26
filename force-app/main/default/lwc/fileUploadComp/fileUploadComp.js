import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { deleteRecord } from 'lightning/uiRecordApi';

export default class FileUploadComp extends LightningElement {
    @api recordId;
    @api acceptedFormats;
    @track fileData = [];

    @wire(graphql, {
        query: "$gqlQuery",
        variables: "$queryData"
    })
    GQLResults({data, error}){
        if(data){
            this.fileData = data.uiapi.query.ContentDocumentLink.edges.map(i=>{
                return {
                    name: `${i.node.ContentDocument.Title.value}.${i.node.ContentDocument.FileExtension.value}`,
                    documentId: i.node.ContentDocument.Id,
                    recordId: i.node.LinkedEntityId.value,
                }
            });
            console.log(JSON.stringify(this.fileData));
        }
        else{
            console.log(error);
        }
    }

    get gqlQuery() {
        return gql`
            query getContentDocumentLink ($recordId: ID!) {
                uiapi {
                    query {
                        ContentDocumentLink(
                            where: {
                                LinkedEntityId: { 
                                    eq: $recordId
                                }
                            }
                        ) {
                            edges{
                                node{
                                    LinkedEntityId {
                                        value
                                    }
                                    ContentDocument {
                                        Id
                                        Title {
                                            value
                                        }
                                        FileExtension {
                                            value
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }`;
    }

    get queryData() {
        return {
          recordId: this.recordId,
        };
    }

    handleUploadFinished(event) {
        event.detail.files.forEach(i=>{
            this.fileData.push({...i});
        });
        this.fireEventToParent('uploadfinished', { name: event.detail.files, recordId: this.recordId });
    }

    removeReceiptImage(event){
        console.log(event.currentTarget.dataset.id);
        this.deleteDocument(this.fileData.filter(ele=>ele.documentId === event.currentTarget.dataset.id)[0]);
    }

    deleteDocument(ObjIds){
        Promise.all([
            deleteRecord(ObjIds.documentId),
            // deleteRecord(ObjIds.contentVersionId),
            // deleteRecord(ObjIds.contentBodyId),
        ])
        .then(res=>{
            const index = this.fileData.findIndex(ele=>ele.documentId === ObjIds.documentId);
            this.fileData.splice(index, 1);
            console.log('deleted successfully', JSON.stringify(this.fileData));
            this.fireEventToParent('delsuccess', { 
                title: `File delete success`,
                message: `${ObjIds.name} deleted successfully!`,
                variant: `success`
            });
        })
        .catch(err=>{
            console.log('something went wrong!', err);
            this.fireEventToParent('delerror', { 
                title: `File delete error`,
                message: `${ObjIds.name} deletion error!`,
                variant: `error`
            });
        });
    }

    fireEventToParent(eventName, data){
        this.dispatchEvent(
            new CustomEvent(eventName, {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: data
                }
            })
        );
    }
}
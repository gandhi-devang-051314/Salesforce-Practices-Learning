import LightningDatatable from 'lightning/datatable';
import htmlFormat from './htmlFormat.html';

export default class CustomDataTable extends LightningDatatable {
    static customTypes = {
        fileUpload: {
            template: htmlFormat,
            typeAttributes: ['acceptedFormats'],
        }
    };
}
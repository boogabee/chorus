chorus.alerts.DatasetNotImportable = chorus.alerts.Base.extend({
    constructorName: "DatasetNotImportable",
    additionalClass: "error",

    preRender: function() {
        var invalidColumns = this.options.datasetImportability.get('invalidColumns'),
            supportedColumnTypes = this.options.datasetImportability.get('supportedColumnTypes');

        this.title = t('dataset.import.not_importable.title');
        this.body = this.bodyContent(invalidColumns, supportedColumnTypes);
    },

    bodyContent: function(invalidColumns, supportedColumnTypes) {
        return Handlebars.helpers.renderTemplate("dataset_not_importable_body", {
            invalidColumns: invalidColumns,
            supportedColumnTypes: supportedColumnTypes
        });
    }
});

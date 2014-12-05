chorus.models.SqlExecutionAndDownloadTask = chorus.models.WorkfileExecutionTask.extend({
    constructorName: "SqlExecutionAndDownloadTask",
    nestParams: false,
    paramsToSave: ['checkId', 'sql', 'schemaId', 'numOfRows', 'fileName'],

    save: function() {
        chorus.fileDownload(this.url(), {
            data: _.extend({
                download: true
            }, this.toJSON()),
            httpMethod: "post",
            successCallback: _.bind(this.saved, this),
            failCallback: _.bind(this.saveFailed, this),
            cookieName: 'fileDownload_' + this.get('checkId')
        });
    },

    saved: function() {
        this.trigger("saved", this);
    },

    saveFailed: function(responseHtml) {
        var responseText = $(responseHtml).text();
        this.handleRequestFailure("saveFailed", {responseText: responseText});
    },

    cancel: function() {
        this._super("cancel");
        chorus.PageEvents.trigger("file:executionCancelled");
    },

    fileName: function() {
        return this.name();
    }
});

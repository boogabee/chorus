chorus.dialogs.DatasetPreview = chorus.dialogs.Base.extend({
    constructorName: "DatasetPreview",
    additionalClass: "dialog_wide",

    templateName: 'dataset_preview',
    title: function() {return t("dataset.data_preview_title", {name: this.model.get("objectName")}); },

    events: {
        "click button.cancel": "cancelTask"
    },

    subviews: {
        '.results_console': 'resultsConsole'
    },

    setup: function() {
        _.bindAll(this, 'title');
        this.resultsConsole = new chorus.views.ResultsConsole({
            footerSize: _.bind(this.footerSize, this),
            showDownloadDialog: true,
            dataset: this.model,
            enableResize: true,
            enableExpander: true,
            verticalDialogPadding: this.verticalPadding
        });
        this.subscribePageEvent("action:closePreview", this.closeModal);
        this.subscribePageEvent("modal:closed", this.cancelTask);
    },

    footerSize: function() {
        return this.$('.form_controls').outerHeight(true);
    },

    postRender: function() {
        this.task = this.model.preview();
        this.resultsConsole.execute(this.task);
    },

    cancelTask: function(e) {
        this.task && this.task.cancel();
    }
});

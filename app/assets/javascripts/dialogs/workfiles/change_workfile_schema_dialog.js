chorus.dialogs.ChangeWorkfileSchema = chorus.dialogs.Base.extend({
    constructorName: "ChangeWorkfileSchema",
    templateName: "change_workfile_schema",

    events: {
        "click button.submit": "save"
    },

    subviews: {
        ".schema_picker": "schemaPicker"
    },

    title: t("schema_picker.change_workfile_schema.title"),

    setup: function() {
        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);

        var options = { showAllDbDataSources: true };

        var schema = this.model.executionSchema();
        if(schema) {
            options.defaultSchema = schema;
        }

        this.schemaPicker = new chorus.views.SchemaPicker(options);
        this.listenTo(this.schemaPicker, "change", this.enableOrDisableSubmitButton);
        this.listenTo(this.schemaPicker, "error", this.showErrors);
        this.listenTo(this.schemaPicker, "clearErrors", this.clearErrors);
    },

    postRender: function() {
        this._super("postRender");
        this.enableOrDisableSubmitButton();
    },

    save: function(e) {
        e.preventDefault();
        this.$("button.submit").startLoading("actions.saving");
        this.$("button.cancel").prop("disabled", true);
        this.model.updateExecutionSchema(this.schemaPicker.getSelectedSchema());
    },

    saved: function() {
        this.closeModal();
        chorus.toast("schema_picker.change_workfile_schema.saved_message");
        chorus.PageEvents.trigger("workfile:changed", this.model);
    },

    saveFailed: function() {
        this.showErrors(this.model);
    },

    enableOrDisableSubmitButton: function() {
        this.$("button.submit").prop("disabled", !this.schemaPicker.ready());
    },

    showErrors: function() {
        this._super("showErrors", arguments);
        var schemaPicker = this.schemaPicker;
        var isForbidden = (schemaPicker.schemaView.collection && schemaPicker.schemaView.collection.statusCode === 403) ||
            (schemaPicker.databaseView.collection && schemaPicker.databaseView.collection.statusCode === 403);
        if(isForbidden) {
            this.showDialogError(t("schema_picker.change_workfile_schema.invalid_credentials"));
        }
    }
});

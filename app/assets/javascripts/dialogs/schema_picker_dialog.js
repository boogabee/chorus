chorus.dialogs.SchemaPicker = chorus.dialogs.Base.extend({
    templateName: "schema_picker_dialog",
    constructorName: "SchemaPicker",

    events: {
        "click button.submit": "save"
    },

    subviews:{
        ".schema_picker":"schemaPicker"
    },

    schemaPickerTranslationKey: function(key) {
        return ["schema_picker", this.options.action, key].join(".");
    },

    setup: function() {
        this.title = t(this.schemaPickerTranslationKey("title"));

        this.schemaPicker = new chorus.views.SchemaPicker({ defaultSchema: this.options.schema });
        this.listenTo(this.schemaPicker, "change", this.enableOrDisableSubmitButton);
        this.listenTo(this.schemaPicker, "error", this.showErrors);
        this.listenTo(this.schemaPicker, "clearErrors", this.clearErrors);
    },

    additionalContext: function() {
        return {
            saveKey: this.schemaPickerTranslationKey("save")
        };
    },

    enableOrDisableSubmitButton:function () {
        this.$("button.submit").prop("disabled", !this.schemaPicker.ready());
    },

    save: function() {
        this.trigger("schema:selected", this.schemaPicker.getSelectedSchema());
        this.closeModal();
    }
});

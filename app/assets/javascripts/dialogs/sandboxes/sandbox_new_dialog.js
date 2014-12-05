chorus.dialogs.SandboxNew = chorus.dialogs.Base.extend({
    constructorName: "SandboxNew",

    templateName: "sandbox_new",
    title: t("sandbox.new_dialog.title"),

    persistent: true,

    events: {
        "click button.submit": "save"
    },

    subviews: {
        "form > .data_source_mode": "schemaPicker"
    },

    setup: function() {
        this.schemaPicker = new chorus.views.SchemaPicker({allowCreate: true});
        this.listenTo(this.schemaPicker, "change", this.enableOrDisableSaveButton);
        this.listenTo(this.schemaPicker, "error", this.showErrors);
        this.listenTo(this.schemaPicker, "clearErrors", this.clearErrors);

        this.workspace.fetch();

        this.requiredResources.add(this.workspace);

        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);
    },

    makeModel: function() {
        this._super("makeModel", arguments);
        this.workspace = this.options.pageModel;
        this.model = new chorus.models.Sandbox({ workspaceId: this.workspace.id });
    },

    resourcesLoaded: function() {
    },

    save: function(e) {
        this.$("button.submit").startLoading("sandbox.adding_sandbox");

        var sandboxId  = this.schemaPicker.schemaId();
        var schemaName = sandboxId ? undefined : this.schemaPicker.fieldValues().schemaName;
        var databaseId = this.schemaPicker.fieldValues().database;
        var databaseName = databaseId ? undefined : this.schemaPicker.fieldValues().databaseName;
        var dataSourceId = this.schemaPicker.fieldValues().dataSource;
        var showSandboxDatasets = this.$(".show_sandbox_datasets").prop("checked");

        this.model.set({
            schemaId: sandboxId,
            schemaName: schemaName,
            databaseId: databaseId,
            databaseName: databaseName,
            dataSourceId: dataSourceId,
            showSandboxDatasets: showSandboxDatasets
        });

        this.model.save();
    },

    saved: function() {
        chorus.toast("sandbox.create.toast");
        this.closeModal();
    },

    enableOrDisableSaveButton: function(schemaVal) {
        this.$("button.submit").prop("disabled", !schemaVal);
    }
});

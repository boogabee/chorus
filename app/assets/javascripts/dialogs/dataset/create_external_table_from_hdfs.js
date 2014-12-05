chorus.dialogs.CreateExternalTableFromHdfs = chorus.dialogs.NewTableImportCSV.extend({
    constructorName: "CreateExternalTableFromHdfs",
    templateName: "create_external_table_from_hdfs",
    title: t("hdfs.create_external.title"),
    useLoadingSection: true,
    loadingKey: "hdfs.create_external.creating",
    includeHeader: false,

    events: {
        "change select": "selectWorkspace"
    },

    setup: function() {
        this.options.csvOptions = this.options.csvOptions || {};
        this.options.csvOptions.hasHeader = false;

        this._super("setup", arguments);

        this.workspaces = new chorus.collections.WorkspaceSet([], {userId: chorus.session.user().id});
        this.workspaces.fetchAll();
        this.requiredResources.push(this.workspaces);
        this.model.set({tableName: chorus.utilities.CsvParser.normalizeForDatabase(this.csvOptions.tableName)});
    },

    postRender: function() {
        this._super("postRender", arguments);

        if (this.workspaces.loaded) {
            if (!this.workspaces.length) {
                this.workspaces.serverErrors = { fields: { workspaces: { EMPTY: {} } } };

                if (chorus.models.Config.instance().license().limitSandboxes()) {
                    this.workspaces.serverErrors = {message: t("not_licensed.for_explorer")};
                }

                this.showErrors(this.workspaces);
                this.$('button.submit').attr('disabled', true);
            }

            this.$("select").val(this.model.get("workspaceId"));

            chorus.styleSelect(this.$("select"));
        }
    },

    saved: function() {
        this.closeModal();
        chorus.toast("hdfs.create_external.success", {workspaceName: this.workspaceName, tableName: this.model.get("tableName")});
        chorus.PageEvents.trigger("csv_import:started");
    },

    updateModel: function() {
        var names = this.importDataGrid.getColumnNames();

        var columnNames = _.map(names, function(name) {
            return chorus.Mixins.dbHelpers.ensureDoubleQuoted(name);
        });

        this.workspaceName = this.$("option:selected").text();
        this.tableName = this.$(".directions input:text").val();

        this.model.set({
            workspaceId: this.$("option:selected").val(),
            delimiter: this.delimiter,
            tableName: chorus.utilities.CsvParser.normalizeForDatabase(this.$(".directions input:text").val()),
            columnNames: columnNames
        });
    },

    performValidation: function() {
        var allValid = true;
        var selectedWorkspace = this.workspaces.get(this.$("option:selected").val());

        var performedValidation = this._super("performValidation");

        if(selectedWorkspace.sandbox().dataSource().version() < "4.1") {
            this.showDialogError(t("hdfs_data_source.gpdb_version.too_old_41"));
            allValid = false;
        }
        return allValid && performedValidation;
    },

    selectWorkspace: function() {
        this.model.set({workspaceId: this.$("option:selected").val()}, {silent: true});
    },

    resourcesLoaded: function() {
        var withSandboxes = this.workspaces.filter(function(ws) {
            return !!ws.sandbox();
        });

        this.workspaces.reset(withSandboxes, {silent: true});
    },

    saveFailed: function() {
        this._super("saveFailed", arguments);
        if (this.model.statusCode === 403) {
            this.showDialogError(t("hdfs_data_source.create_external.invalid_sandbox_credentials"));
        }
    },

    additionalContext: function() {
        var parentCtx = this._super("additionalContext", arguments);
        parentCtx.workspaces = _.pluck(this.workspaces.models, "attributes");
        parentCtx.directions = new Handlebars.SafeString("<input type='text' class='hdfs' name='tableName' value='" + Handlebars.Utils.escapeExpression(this.model.get("tableName")) + "'/>");
        return parentCtx;
    }
});

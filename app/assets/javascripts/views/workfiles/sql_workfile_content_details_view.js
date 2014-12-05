chorus.views.SqlWorkfileContentDetails = chorus.views.WorkfileContentDetails.extend({
    templateName: "sql_workfile_content_details",
    constructorName: "SqlWorkContentDetailsView",

    setup: function() {
        this._super("setup", arguments);
        this.subscribePageEvent("file:selectionPresent", this.onSelectedText);
        this.subscribePageEvent("file:selectionEmpty", this.onNoSelectedText);
        this.contentView = this.options.contentView;
    },

    events: {
        'click a.change_workfile_schema': 'changeWorkfileSchema'
    },

    postRender: function() {
        this._super("postRender");
        this.menu(this.$('.run_file'), {
            content: this.$(".run_workfile"),
            orientation: "right",
            qtipArgs: {
                events: {
                    show: _.bind(function(e) {
                        $(".run_workfile .run_selection, .run_workfile .run_selection_and_download").toggleClass("disabled", !this.enableRunSelection());
                    }, this)
                }
            },
            contentEvents: {
                "a.run_default": this.runInExecutionSchema,
                "a.run_selection": this.runSelectedInExecutionSchema,
                "a.run_and_download": this.runAndDownloadInExecutionSchema,
                "a.run_selection_and_download": this.runSelectionAndDownloadInExecutionSchema
            }
        });

        if (!this.model.workspace().isActive() || !this.model.workspace().canUpdate()) {
            this.$(".run_file").attr("disabled", "disabled");
            this.$(".save button").attr("disabled", "disabled");
            this.$(".change_workfile_schema").remove();
        }

        if (!this.hasValidExecutionSchema()) {
            this.fileMenu.disableItem("newChorusView");
            this.fileMenu.disableItem("newSelectionChorusView");
        }

        this.fileMenu.disableItem("newSelectionChorusView");

        chorus.PageEvents.trigger("file:editorSelectionStatus");
    },

    fileMenuItems: function() {
        var items = this._super("fileMenuItems", arguments);
        items.push({
            name: "newChorusView",
            text: t("workfile.content_details.save_as_chorus_view"),
            onSelect: _.bind(this.createChorusViewFromFile, this)
        });
        items.push({
            name: "newSelectionChorusView",
            text: t("workfile.content_details.save_selection_as_chorus_view"),
            onSelect: _.bind(this.createChorusViewFromSelection, this)
        });
        return items;
    },

    enableRunSelection: function() {
        return !!(this.contentView.getSelectedText() && this.hasValidExecutionSchema());
    },

    hasValidExecutionSchema: function() {
        return !!(this.model.executionSchema());
    },

    additionalContext: function() {
        var ctx = this._super("additionalContext");

        var executionSchema = this.model.executionSchema();
        var sandboxSchema = this.model.sandbox() && this.model.sandbox().schema();
        return _.extend(ctx, {
            schemaName: executionSchema && executionSchema.canonicalName(),
            executionSchemaIsSandbox: (executionSchema && sandboxSchema && executionSchema.isEqualToSchema(sandboxSchema))
        });
    },

    onSelectedText: function() {
        this.$(".run_file .run_description").text(t("workfile.content_details.run_selected"));

        if (this.hasValidExecutionSchema()) {
            this.fileMenu.enableItem("newSelectionChorusView");
        }
    },

    onNoSelectedText: function() {
        this.$(".run_file .run_description").text(t("workfile.content_details.run_file"));
        this.fileMenu.disableItem("newSelectionChorusView");
    },

    createChorusViewFromFile: function() {
        chorus.PageEvents.trigger("file:newChorusView");
    },

    createChorusViewFromSelection: function() {
        chorus.PageEvents.trigger("file:newSelectionChorusView");
    },

    runInExecutionSchema: function() {
        chorus.PageEvents.trigger("file:runCurrent");
    },

    runSelectedInExecutionSchema: function() {
        if (this.enableRunSelection()) {
            chorus.PageEvents.trigger("file:runSelected");
        }
    },

    runAndDownloadInExecutionSchema: function() {
        this.dialog = new chorus.dialogs.RunAndDownload({ model: this.model });
        this.dialog.launchModal();
    },

    runSelectionAndDownloadInExecutionSchema: function() {
        this.dialog = new chorus.dialogs.RunAndDownload({ model: this.model, selection: true });
        this.dialog.launchModal();
    },

    changeWorkfileSchema: function(e) {
        e.preventDefault();

        if (this.model.workspace().isActive() && this.model.workspace().canUpdate()) {
            chorus.PageEvents.trigger("file:saveDraft");
            this.dialog = new chorus.dialogs.ChangeWorkfileSchema({ model: this.model });
            this.dialog.launchModal();
        }
    }
});


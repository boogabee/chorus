chorus.dialogs.WorkspaceFileImport = chorus.dialogs.Upload.extend({
    constructorName: "WorkspaceFileImport",

    templateName: "dataset_import",
    title: t("dataset.import.title"),

    makeModel: function() {
        this.workspace = this.options.pageModel;
        this.resource = this.model = this.csvImport = new chorus.models.CSVImport({ workspaceId: this.workspace.id });
        this.csvOptions = {hasHeader: true};
    },

    events: _.extend({
        "change input:radio": "onRadioSelect",
        "click a.dataset_picked": "launchDatasetPickerDialog"
    }, this.events),

    launchDatasetPickerDialog: function(e) {
        e.preventDefault();
        if (!this.saving) {
            var datasetDialog = new chorus.dialogs.DatasetsPicker({ collection: this.workspace.sandboxTables({allImportDestinations: true}) });
            this.listenTo(datasetDialog, "datasets:selected", this.datasetsChosen);
            this.launchSubModal(datasetDialog);
        }
    },

    datasetsChosen: function(dataset) {
        this.selectedDataset = dataset[0];
        this.changeSelectedDataset(dataset && dataset[0] && dataset[0].name());
    },

    onRadioSelect: function(e) {
        this.$(".new_table input:text").prop("disabled", true);
        this.$(".existing_table select").prop("disabled", true);
        this.$(".existing_table .options").addClass('hidden');
        this.$(".existing_table .options input").prop("disabled", true);

        this.importTarget = $(e.currentTarget).val();
        if (this.importTarget === "new") {
            this.$(".new_table input:text").prop("disabled", false);
            this.$("button.submit").prop("disabled", false);
            this.$("a.dataset_picked").addClass("hidden");

            if (this.selectedDataset) {
                this.$("span.dataset_picked").removeClass("hidden");
            }

        } else if (this.importTarget === "existing") {
            this.$("a.dataset_picked").removeClass("hidden");
            this.$("span.dataset_picked").addClass("hidden");

            this.$(".existing_table .options").removeClass("hidden");
            this.$(".existing_table .options input").prop("disabled", false);
        }

        this.enableButton();
    },

    changeSelectedDataset: function(name) {
        this.$(".existing_table a.dataset_picked").text(_.prune(name, 20));
        this.$(".existing_table span.dataset_picked").text(_.prune(name, 20));

        this.enableButton();
    },

    enableButton: function() {
        if (this.selectedDataset || this.importTarget !== "existing") {
            this.$("button.submit").prop("disabled", false);
        } else {
            this.$("button.submit").prop("disabled", true);
        }
    },

    additionalContext: function() {
        var workspace = this.workspace;
        var sandbox = workspace.sandbox();
        var canonicalName = sandbox.canonicalName();

        return { canonicalName: canonicalName };
    },

    importDestination: function() {
        if (this.importTarget === "existing") {
            return (this.selectedDataset && this.selectedDataset.name()) || "";
        } else if (this.importTarget === "new") {
            return chorus.utilities.CsvParser.normalizeForDatabase(this.$('.new_table input:text').val());
        }
    },

    uploadFile: function(e) {
        e && e.preventDefault();
        this.$("button.choose").prop("disabled", true);
        this.$(".file-wrapper a").addClass("hidden");
        this.$(".import_controls input[type=radio]").prop("disabled", true);
        if (this.importTarget === "workfile") {
            this.$("button.submit").startLoading("actions.uploading");
            this.uploadObj.paramName = "workfile[versions_attributes][0][contents]";
            this.uploadObj.url = "/workspaces/" + this.workspace.id + "/workfiles";
            this.uploadObj.source = "fs";
            this.request = this.uploadObj.submit();
        } else {
            this.csvOptions.tableName = this.importDestination();

            this.csvImport.set({
                destinationType: this.importTarget,
                toTable: this.importDestination(),
                truncate: this.$(".existing_table input#truncate").is(':checked')
            }, {silent: true});

            if (this.csvImport.performValidation()) {
                this.$("button.submit").startLoading("actions.uploading");
                this.clearErrors();
                this.uploadObj.url = "/workspaces/" + this.workspace.id + "/csv";
                this.uploadObj.type = "POST";
                this.uploadObj.source = "fs";
                this.request = this.uploadObj.submit();
            } else {
                this.$("button.choose").prop("disabled", false);
                this.$(".file-wrapper a").removeClass("hidden");
                this.$(".import_controls input[type=radio]").prop("disabled", false);
                this.showErrors(this.model);
            }
        }
    },

    uploadFinished: function(e) {
        e && e.preventDefault();
        this.$(".import_controls input[type=radio]").prop("disabled", false);

        this._super("uploadFinished", arguments);
    },

    uploadSuccess: function(e, data) {
        e && e.preventDefault();

        if (this.importTarget === "workfile") {
            var workfile = new chorus.models.Workfile();
            workfile.set(workfile.parse(data.result), {silent: true});

            chorus.toast("dataset.import.workfile_success", {fileName: workfile.get("fileName")});
            chorus.router.navigate(workfile.hasOwnPage() ? workfile.showUrl() : workfile.workfilesUrl());
        } else {
            var workingCsvImport = this.csvImport.clone();
            var contents = data.result.response.contents;
            this.csvOptions.contents = contents;
            var csvId = data.result.response.id;
            workingCsvImport.set({
                csvId:csvId,
                contents:contents
            });

            var csvParser = new chorus.utilities.CsvParser(contents, this.csvOptions);
            if ((csvParser.getColumnOrientedData().length === 0) && !csvParser.serverErrors) {
                var alert = new chorus.alerts.EmptyCSV();
                alert.launchModal();
            } else {
                var dialog;
                if (this.importTarget === "existing") {
                    dialog = new chorus.dialogs.ExistingTableImportCSV({model: workingCsvImport, datasetId: this.selectedDataset.get("id"), csvOptions: this.csvOptions});
                } else {
                    dialog = new chorus.dialogs.NewTableImportCSV({model: workingCsvImport, csvOptions: this.csvOptions});
                }
                this.subscribePageEvent("csv_import:started", this.closeModal);
                dialog.launchModal();
            }
        }
    },

    fileChosen: function(e, data) {
        this.$(".import_controls").removeClass("hidden");

        this._super("fileChosen", arguments);
    },

    maxFileSize: function() {
        return this.config.get("fileSizesMbCsvImports");
    },

    postRender: function() {
        this.importTarget = "new";

        this._super("postRender", arguments);
    }
});

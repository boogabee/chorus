chorus.dialogs.ConfigureImportSourceDataTask = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'ConfigureImportSourceDataTask',
    templateName: 'configure_import_source_data_task_dialog',
    message: "create_job_task_dialog.toast",
    focusSelector: null,
    title: function () {
        return this.model.isNew() ? t('create_job_task_dialog.add_title') : t('create_job_task_dialog.edit_title');
    },
    submitButtonTranslationKey: function () {
        return this.model.isNew() ? 'create_job_task_dialog.add' : 'create_job_task_dialog.save';
    },


    events: {
        "change input:radio": "onExistingTableChosenAsDestination",
        "change input:checkbox": "onCheckboxClicked",
        "click .source a.dataset_picked": "launchSourceDatasetPickerDialog",
        "click .destination a.dataset_picked": "launchDestinationDatasetPickerDialog"
    },

    setup: function () {
        this.job = this.options.job || this.model.job();
        this.workspace = chorus.page.workspace;
        if (this.model) {
            this.sourceTableHasBeenPicked = true;
            if (this.model.get('destinationId')) {
                this.destinationTableHasBeenPicked = true;
            }
        } else {
            this.model = this.buildATask();
        }
        this.resource = this.model;

        if (!this.workspace.sandbox()) {
            this.resource.serverErrors = {"fields":{"base":{"EMPTY_SANDBOX":{}}}};
            this.showErrors();
        }

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, "saveFailed validationFailed", this.saveFailed);
    },

    postRender: function () {
        this.updateExistingTableLink();

        _.defer(_.bind(function () {
            chorus.styleSelect(this.$("select"));
        }, this));
    },

    additionalContext: function () {
        return {
            submitButtonTranslationKey: this.submitButtonTranslationKey(),
            useExistingTable: this.model.isNew() || this.model.get('destinationId'),
            rowLimit: this.model.get('rowLimit') || 500,
            sourceName: this.model.get('sourceName'),
            destinationId: this.model.get('destinationId'),
            destinationName: this.model.get('destinationName'),
            truncate: this.model.get('truncate')
        };
    },

    checkInput: function () {
        var importIntoExisting = this.$(".choose_table input:radio").prop("checked");
        var newTableNameGiven = this.$('input.new_table_name').val().trim().length > 0;

        var existingDestinationPicked = importIntoExisting && this.destinationTableHasBeenPicked;
        var newDestinationNamed = (!importIntoExisting && newTableNameGiven);

        var sourcePicked = this.sourceTableHasBeenPicked;
        var destinationPicked = existingDestinationPicked || newDestinationNamed;

        return sourcePicked && destinationPicked;
    },

    buildATask: function () {
        return new chorus.models.JobTask({
            job: { id: this.job.get("id"), workspace: { id: this.workspace.get("id") } }
        });
    },

    isNewTable: function () {
        return this.$('.new_table input:radio').prop('checked');
    },

    onExistingTableChosenAsDestination: function () {
        this.clearErrors();
        this.updateExistingTableLink();
    },

    updateExistingTableLink: function () {
        var destinationIsNewTable = this.$(".new_table input:radio").prop("checked");

        var $tableNameField = this.$(".new_table input.new_table_name");
        $tableNameField.prop("disabled", !destinationIsNewTable);

        this.enableDestinationLink(!destinationIsNewTable);
        this.showErrors(this.model);
        this.toggleSubmitDisabled();
    },

    enableDestinationLink: function (enable) {
        var $a = this.$(".destination a.dataset_picked");
        var $span = this.$(".destination span.dataset_picked");

        if (enable) {
            $a.removeClass("hidden");
            $span.addClass("hidden");
        } else {
            $a.addClass("hidden");
            $span.removeClass("hidden");
        }
    },

    sourceTableHasBeenPicked: false,
    destinationTableHasBeenPicked: false,

    limitIsChecked: function () {
        return this.$("input[name=limit_num_rows]").prop("checked");
    },

    truncateIsChecked: function () {
        return this.$("input.truncate").prop("checked");
    },

    newTableName: function () {
        return this.$('input.new_table_name').val();
    },

    onCheckboxClicked: function (e) {
        this.$(".limit input:text").prop("disabled", !this.limitIsChecked());
        this.toggleSubmitDisabled();
    },

    datasetsChosen: function (datasets, source_or_destination) {
        if (source_or_destination === 'destination') {
            this.destinationTableHasBeenPicked = true;
            this.selectedDestinationDatasetId = datasets[0].get("id");
        }
        if (source_or_destination === 'source') {
            this.sourceTableHasBeenPicked = true;
            this.selectedSourceDatasetId = datasets[0].get("id");
        }

        var selector = '.' + source_or_destination;
        this.changeSelectedDataset(datasets && datasets[0] && datasets[0].name(), selector);
    },

    changeSelectedDataset: function (name, target) {
        if (name) {
            this.$(target + " a.dataset_picked").text(_.prune(name, 20));
            this.$(target + " span.dataset_picked").text(_.prune(name, 20));
            this.toggleSubmitDisabled();
        }
    },

    create: function () {
        this.$("button.submit").startLoading('actions.saving');
        this.model.save(this.fieldValues(), {wait: true});
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.job.trigger('invalidated');
        this.closeModal();
    },

    fieldValues: function () {
        var updates = {
            action: "import_source_data",
            sourceId: this.selectedSourceDatasetId,
            destinationId: this.selectedDestinationDatasetId,
            rowLimit: this.limitIsChecked() ? this.$("input.row_limit").val() : '',
            truncate: this.truncateIsChecked()
        };

        if (this.isNewTable()) {
            updates.destinationName = this.newTableName();
        } else {
            updates.destinationId = this.selectedDestinationDatasetId;
        }

        return updates;
    },

    launchDatasetPickerDialog: function (e, source_or_destination) {
        e.preventDefault();
        if (this.saving || !this.workspace.sandbox()) {
            return;
        }

        var tables = source_or_destination === "source" ? this.workspace.importSourceDatasets() : this.workspace.sandboxTables({allImportDestinations: true});
        var datasetDialog = new chorus.dialogs.DatasetsPicker({ collection: tables, title: t("dataset.pick_" + source_or_destination) });

        this.listenTo(datasetDialog, "datasets:selected", function (datasets) {
            return this.datasetsChosen(datasets, source_or_destination);
        });

        this.launchSubModal(datasetDialog);
    },

    launchSourceDatasetPickerDialog: function (e) {
        this.launchDatasetPickerDialog(e, 'source');
    },

    launchDestinationDatasetPickerDialog: function (e) {
        this.launchDatasetPickerDialog(e, 'destination');
    }
});

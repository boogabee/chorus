chorus.dialogs.ImportNow = chorus.dialogs.Base.extend({
    constructorName: "ImportNowDialog",
    templateName: "import_now",

    useLoadingSection: true,
    persistent: true,

    events: {
        "change input:radio": "onDestinationChosen",
        "change input:checkbox": "onCheckboxClicked",
        "keyup input:text": "onInputFieldChanged",
        "paste input:text": "onInputFieldChanged",
        "cut input:text": "onInputFieldChanged",
        "click button.submit": "saveModel",
        "click button.cancel": "onClickCancel",
        "click .existing_table a.dataset_picked": "launchDatasetPickerDialog",
        "click a.select_schema": "launchSchemaPickerDialog",
        "click a.change_schema": "launchSchemaPickerDialog"
    },

    makeModel: function() {
        this.dataset = this.options.dataset;
        this.workspace = this.dataset.workspace();

        if(this.workspace) {
            this.schema = this.workspace.sandbox().schema();
            this.model = new chorus.models.WorkspaceImport({
                datasetId: this.dataset.get("id"),
                workspaceId: this.workspace.id
            });
        } else {
            this.model = new chorus.models.SchemaImport({
                datasetId: this.dataset.get("id")
            });
        }

        this.model.loaded = true;
    },

    setup: function() {
        this.customSetup();

        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, "saveFailed validationFailed", function() {
            this.showErrors(this.model);
            this.$("button.submit").stopLoading();
        });

        this.checkImportability();
    },

    checkImportability: function() {
        this.importability = new chorus.models.DatasetImportability({
            datasetId: this.options.dataset.id
        });
        this.importability.fetch({
            success: _.bind(function() {
                if (this.importability.get('importability')) {
                    this.$(".dialog_content").stopLoading();
                } else {
                    this.closeModal();
                    new chorus.alerts.DatasetNotImportable({
                        datasetImportability: this.importability
                    }).launchModal();
                }
            }, this)
        });
    },

    customSetup: function() {
        this.title = t("import.title");
        this.submitKey = "import.begin";
    },

    saveModel: function() {
        this.$("button.submit").startLoading("import.importing");

        this.model.unset("sampleCount", {silent: true});
        this.model.save(this.getNewModelAttrs());
    },

    modelSaved: function() {
        chorus.toast("import.success");
        this.dataset.trigger('change');
        this.closeModal();
    },

    postRender: function() {
        this.$(".truncate").prop("disabled", true);
        this.updateExistingTableLink();

        if (!this.workspace && !this.importability.loaded) {
            this.$(".dialog_content").startLoading();
        }
    },

    launchDatasetPickerDialog: function(e) {
        e.preventDefault();
        if(!this.saving) {
            var tables = this.workspace ? this.workspace.sandboxTables({allImportDestinations: true}) : this.schema.tables();

            var pickerOptions = {
                collection: tables
            };

            var datasetDialog = new chorus.dialogs.DatasetsPicker(pickerOptions);
            this.listenTo(datasetDialog, "datasets:selected", this.datasetsChosen);
            this.launchSubModal(datasetDialog);
        }
    },

    datasetsChosen: function(datasets) {
        this.changeSelectedDataset(datasets && datasets[0] && datasets[0].name());
    },

    changeSelectedDataset: function(name) {
        if(name) {
            this.selectedDatasetName = name;
            this.$(".existing_table a.dataset_picked").text(_.prune(name, 20));
            this.$(".existing_table span.dataset_picked").text(_.prune(name, 20));
            this.onInputFieldChanged();
        }
    },

    launchSchemaPickerDialog: function(e) {
        e.preventDefault();
        var schemaPickerDialog = new chorus.dialogs.SchemaPicker({
            action: "select_import_schema"
        });
        this.listenTo(schemaPickerDialog, "schema:selected", this.schemaChosen);
        this.launchSubModal(schemaPickerDialog);
    },

    schemaChosen: function(schema) {
        this.schema = schema;
        this.$(".selection").text(_.truncate(schema.canonicalName(), 40));
        this.$(".selection").attr("title", schema.canonicalName());
        this.$("a.select_schema").addClass("hidden");
        this.$("a.change_schema").removeClass("hidden");
        this.updateInputState();
    },

    isNewTable: function() {
        return this.$('#import_now_new_table').prop('checked');
    },

    onDestinationChosen: function() {
        this.clearErrors();
        this.updateExistingTableLink();

        this.$(".truncate").prop("disabled", this.isNewTable());
    },

    updateExistingTableLink: function() {
        var destinationIsNewTable = this.$(".new_table input:radio").prop("checked");

        var $tableNameField = this.$(".new_table input.name");
        $tableNameField.prop("disabled", !destinationIsNewTable);

        this.enableDestinationLink(!destinationIsNewTable);
        this.onInputFieldChanged();
    },

    enableDestinationLink: function(enable) {
        var $a = this.$(".existing_table a.dataset_picked");
        var $span = this.$(".existing_table span.dataset_picked");

        if(enable) {
            $a.removeClass("hidden");
            $span.addClass("hidden");
        } else {
            $a.addClass("hidden");
            $span.removeClass("hidden");
        }
    },

    additionalContext: function() {
        return {
            allowSchemaSelection: !this.workspace,
            canonicalName: this.schema && this.schema.canonicalName(),
            submitKey: this.submitKey
        };
    },

    onInputFieldChanged: function(e) {
        this.showErrors(this.model);
        var changeType = e && e.type;
        if(changeType === "paste" || changeType === "cut") {
            //paste and cut events fire before they actually update the input field
            _.defer(_.bind(this.updateInputState, this));
        } else {
            this.updateInputState();
        }
    },

    updateInputState: function() {
        var importIntoExisting = this.$('.existing_table input:radio').prop("checked");
        var newTableNameGiven = this.$('input.name').val().trim().length > 0;

        var formIsValid = (importIntoExisting && this.destinationTableHasBeenPicked() ||
            (!importIntoExisting && newTableNameGiven));

        formIsValid = formIsValid && !!this.schema;

        this.$('button.submit').prop('disabled', !formIsValid);

        if(!this.workspace) {
            this.$(".options").toggleClass("hidden", !this.schema);
        }
    },

    onCheckboxClicked: function(e) {
        var limitRows = this.$("input[name=limit_num_rows]").prop("checked");
        var $limitInput = this.$(".limit input:text");

        $limitInput.prop("disabled", !limitRows);
        this.updateInputState();
    },

    getNewModelAttrs: function() {
        var updates = {};

        updates.newTable = this.isNewTable() + "";
        updates.schemaId = this.schema.id;

        if(this.isNewTable()) {
            updates.toTable = this.$("input[name=toTable]").val();
        } else {
            updates.toTable = this.selectedDatasetName;
        }

        var $truncateCheckbox = this.$(".truncate");
        if($truncateCheckbox.length) {
            updates.truncate = $truncateCheckbox.prop("checked") + "";
        }

        var useLimitRows = this.$(".limit input:checkbox").prop("checked");
        if(!useLimitRows) {
            updates.sampleCount = '';
        } else {
            updates.sampleCount = this.$("input[name='sampleCount']").val();
        }

        return updates;
    },

    onClickCancel: function() {
        this.model.clearErrors();
        this.closeModal();
    },

    destinationTableHasBeenPicked: function() {
        return this.$("a.dataset_picked").text() !== t("dataset.import.select_destination");
    }
});

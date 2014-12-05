chorus.dialogs.ExistingTableImportCSV = chorus.dialogs.Base.extend({
    constructorName: "ExistingTableImportCSV",

    templateName: "existing_table_import_csv",
    additionalClass: "table_import_csv dialog_wide",
    title: t("dataset.import.table.title"),
    delimiter: ',',

    subviews: {
        ".result_table": "dataGrid"
    },

    events: {
        "click button.submit": "startImport",
        "change #hasHeader": "refreshCSV",
        "keyup input.delimiter[name=custom_delimiter]": "setOtherDelimiter",
        "paste input.delimiter[name=custom_delimiter]": "setOtherDelimiter",
        "click input.delimiter[type=radio]": "setDelimiter",
        "click input#delimiter_other": "focusOtherInputField",
        "click a.automap": "automap"
    },

    setup: function() {
        this.csvOptions = this.options.csvOptions;
        this.tableName = this.csvOptions.tableName;
        this.dataset = new chorus.models.WorkspaceDataset({ workspace: {id: this.model.get("workspaceId")}, id: this.options.datasetId });

        this.requiredResources.add(this.dataset);
        this.dataset.fetch();

        this.columnSet = this.dataset.columns();
        this.requiredResources.add(this.columnSet);
        this.columnSet.fetchAll();

        this.dataGrid = new chorus.views.ExistingTableImportDataGrid();

        var parser = new chorus.utilities.CsvParser(this.csvOptions.contents, this.csvOptions);
        var columns = parser.getColumnOrientedData();

        this.initializeModel(columns);

        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.validationFailed);
        this.listenTo(this.dataGrid, "updatedDestinationCount", this.updateDestinationCount);
    },

    resourcesLoaded: function() {
        this.dataGrid.setDestinationColumns(this.columnSet.models);
    },

    initializeModel: function(columnData) {
        this.model.set({
            hasHeader: this.csvOptions.hasHeader,
            tableName: chorus.utilities.CsvParser.normalizeForDatabase(this.csvOptions.tableName),
            types: _.pluck(columnData, 'type')
        });
    },

    saved: function() {
        this.closeModal();
        chorus.toast("dataset.import.started");
        chorus.PageEvents.trigger("csv_import:started");
        chorus.router.navigate(this.dataset.showUrl());
    },

    validationFailed: function() {
        this.saveFailed();
        this.$("button.submit").prop("disabled", true);
    },

    postRender: function() {
        this.cleanUpQtip();
        if (this.dataset.loaded) {
            this.validateColumns();
        }

        if (this.model.serverErrors) {
            this.showErrors();
        }

        this.initializeDataPreview();
        this.selectStartingDelimiter();
    },

    initializeDataPreview: function () {
        var csvParser = new chorus.utilities.CsvParser(this.csvOptions.contents, this.model.attributes);
        var sourceColumns = csvParser.getColumnOrientedData();
        var rows = csvParser.rows();
        var sourceColumnNames = _.pluck(sourceColumns, "name");
        this.dataGrid.initializeDataGrid(sourceColumns, rows, sourceColumnNames);
    },

    selectStartingDelimiter: function () {
        this.$("input.delimiter").prop("checked", false);
        if (_.contains([",", "\t", ";", " "], this.delimiter)) {
            this.$("input.delimiter[value='" + this.delimiter + "']").prop("checked", true);
        } else {
            this.$("input#delimiter_other").prop("checked", true);
        }
    },

    updateDestinationCount: function(counts) {
        var frequenciesBySourceColumn = counts.frequencies;
        var invalidMapping = _.any(frequenciesBySourceColumn, function(f) { return f !== 1; });

        this.$("button.submit").prop("disabled", invalidMapping);
        this.$(".progress").text(t("dataset.import.table.progress", counts));
    },

    additionalContext: function() {
        return {
            delimiter: this.other_delimiter ? this.delimiter : '',
            directions: t("dataset.import.table.existing.directions", {
                toTable: Handlebars.helpers.spanFor(this.model.get("tableName"), {"class": "destination"})
            })
        };
    },

    startImport: function() {
        this.$('button.submit').startLoading("dataset.import.importing");

        this.model.set({
            delimiter: this.delimiter,
            type: "existingTable",
            hasHeader: !!(this.$("#hasHeader").prop("checked")),
            columnNames: this.dataGrid.columnMapping
        }, { silent: true });

        this.$("button.submit").startLoading("dataset.import.importing");

        this.model.save();
    },

    refreshCSV: function() {
        this.model.set({hasHeader: !!(this.$("#hasHeader").prop("checked")), delimiter: this.delimiter});

        var options = _.clone(this.csvOptions);
        options.delimiter = this.delimiter;

        var parser = new chorus.utilities.CsvParser(this.csvOptions.contents, options);
        var columnData = parser.getColumnOrientedData();

        this.model.set({types: _.pluck(columnData, 'type')});

        this.render();
    },

    setDelimiter: function(e) {
        if (e.target.value === "other") {
            this.delimiter = this.$("input[name=custom_delimiter]").val();
            this.other_delimiter = true;
        } else {
            this.delimiter = e.target.value;
            this.other_delimiter = false;
        }

        this.model.unset("headerColumnNames", {silent: true});
        this.model.unset("generatedColumnNames", {silent: true});

        this.refreshCSV();
    },

    focusOtherInputField: function() {
        this.$("input[name=custom_delimiter]").focus();
    },

    setOtherDelimiter: function() {
        this.$("input.delimiter[type=radio]").prop("checked", false);
        var otherRadio = this.$("input#delimiter_other");
        otherRadio.prop("checked", true);
        otherRadio.click();
    },

    cleanUpQtip: function() {
        this.$(".column_mapping").qtip("destroy");
        this.$(".column_mapping").removeData("qtip");
    },

    validateColumns: function() {
        this.clearErrors();
        var parser = new chorus.utilities.CsvParser(this.csvOptions.contents, this.model.attributes);
        var columnData = parser.getColumnOrientedData();
        var sourceColumnsNum = columnData.length;

        this.model.serverErrors = parser.serverErrors;

        var destinationColumnsNum = this.dataGrid.destinationColumns ? this.dataGrid.destinationColumns.length : 0;
        if (destinationColumnsNum < sourceColumnsNum) {
            this.resource.serverErrors = { fields: { source_columns: { LESS_THAN_OR_EQUAL_TO: {} } } };
            this.resource.trigger("validationFailed");
        }
    },

    automap: function(e) {
        e && e.preventDefault();
        this.dataGrid.automap();
    }
});

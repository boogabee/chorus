chorus.dialogs.NewTableImportCSV = chorus.dialogs.Base.extend({
    constructorName: "NewTableImportCSV",
    suppressRenderOnChange: true,
    templateName: "new_table_import_csv",
    additionalClass: "table_import_csv dialog_wide",
    title: t("dataset.import.table.title"),
    loadingKey: "dataset.import.importing",
    includeHeader: true,

    delimiter: ',',

    subviews: {
        ".result_table": "importDataGrid"
    },

    events: {
        "click button.submit": "startImport",
        "change #hasHeader": "setHeader",
        "keyup input.delimiter[name=custom_delimiter]": "setOtherDelimiter",
        "paste input.delimiter[name=custom_delimiter]": "setOtherDelimiter",
        "click input.delimiter[type=radio]": "setDelimiter",
        "click input#delimiter_other": "focusOtherInputField"
    },

    setup: function() {
        this.csvOptions = this.options.csvOptions;
        this.model = this.options.model;
        this.contents = this.csvOptions.contents;

        this.model.set({
            hasHeader: this.csvOptions.hasHeader,
            tableName: chorus.utilities.CsvParser.normalizeForDatabase(this.csvOptions.tableName)
        });

        this.csvParser = new chorus.utilities.CsvParser(this.contents, this.model.attributes);
        this.generateColumnNames();

        this.importDataGrid = new chorus.views.NewTableImportDataGrid();

        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);
    },

    generateColumnNames: function() {
        var headerRow = this.csvParser.parseColumnNames();
        this.headerColumnNames = headerRow;
        this.generatedColumnNames = _.map(headerRow, function(column, i) {
            return "column_" + (i + 1);
        });
    },

    postRender: function() {
        var columns = this.csvParser.getColumnOrientedData();
        var rows = this.csvParser.rows();
        this.model.serverErrors = this.csvParser.serverErrors;
        this.model.set({
            types: _.pluck(columns, "type")
        }, {silent: true});

        if(this.model.serverErrors) {
            this.showErrors();
        }

        this.$("input.delimiter").prop("checked", false);
        if(_.contains([",", "\t", ";", " "], this.delimiter)) {
            this.$("input.delimiter[value='" + this.delimiter + "']").prop("checked", true);
        } else {
            this.$("input#delimiter_other").prop("checked", true);
        }
        this.importDataGrid.initializeDataGrid(columns, rows, this.getColumnNames());
    },

    revealed: function() {
        this._super("revealed", arguments);
        var columns = this.csvParser.getColumnOrientedData();
        var rows = this.csvParser.rows();
        this.importDataGrid.initializeDataGrid(columns, rows, this.getColumnNames());
    },

    additionalContext: function() {
        return {
            includeHeader: this.includeHeader,
            columns: this.csvParser.getColumnOrientedData(),
            delimiter: this.other_delimiter ? this.delimiter : '',
            directions: Handlebars.helpers.unsafeT("dataset.import.table.new.directions", {
                tablename_input_field: "<input type='text' name='tableName' value='" + this.model.get('tableName') + "'/>"
            })
        };
    },

    saved: function() {
        this.closeModal();
        chorus.toast("dataset.import.started");
        chorus.PageEvents.trigger("csv_import:started");
    },

    saveFailed: function() {
        if(this.model.serverErrors) {
            this.showErrors();
        }

        this.$("button.submit").stopLoading();
    },

    storeColumnInfo: function() {
        this.storeColumnNames();
        this.storeColumnTypes();
    },

    storeColumnNames: function() {
        var names = this.importDataGrid.getColumnNames();
        if(names.length) {
            if(this.model.get("hasHeader")) {
                this.headerColumnNames = names;
            } else {
                this.generatedColumnNames = names;
            }
        }
    },

    storeColumnTypes: function() {
        this.model.set({types: this.importDataGrid.getColumnTypes()}, {silent: true});
    },

    getColumnNames: function() {
        return this.model.attributes.hasHeader ? this.headerColumnNames : this.generatedColumnNames;
    },

    startImport: function() {
        if(this.performValidation()) {
            this.storeColumnInfo();
            this.updateModel();

            this.$("button.submit").startLoading(this.loadingKey);
            this.model.save();
        }
    },

    performValidation: function() {
        var pattern = chorus.ValidationRegexes.ChorusIdentifier64();
        var allValid = true;
        var invalidCount = 0;

        var $tableName = this.$(".directions input:text");

        this.clearErrors();

        if(!$tableName.val().match(pattern)) {
            allValid = false;
            this.markInputAsInvalid($tableName, t("import.validation.toTable.required"), true);
        }

        var names = this.importDataGrid.getColumnNames();
        _.each(names, function(name, i) {
            if(!name.match(pattern)) {
                allValid = false;
                invalidCount += 1;
                this.importDataGrid.markColumnNameInputAsInvalid(i);
            }
        }, this);

        if(!allValid && invalidCount > 0) {
            this.showDialogError(t("dataset.import.invalid_columns", {numInvalid: invalidCount, numTotal: names.length}));
        }

        return allValid;
    },

    updateModel: function() {
        var newTableName = chorus.utilities.CsvParser.normalizeForDatabase(this.$(".directions input:text").val());
        this.model.set({
            hasHeader: !!(this.$("#hasHeader").prop("checked")),
            delimiter: this.delimiter,
            tableName: newTableName,
            toTable: newTableName,
            columnNames: this.getColumnNames()
        });
    },

    parseCsv: function() {
        this.csvParser.setOptions({
            hasHeader: !!(this.$("#hasHeader").prop("checked")),
            delimiter: this.delimiter
        });
        this.csvParser.parse();
    },

    setHeader: function() {
        this.storeColumnInfo();
        this.parseCsv();
        this.updateModel();
        this.render();
    },

    focusOtherInputField: function(e) {
        this.$("input[name=custom_delimiter]").focus();
    },

    setDelimiter: function(e) {
        if(e.target.value === "other") {
            this.delimiter = this.$("input[name=custom_delimiter]").val();
            this.other_delimiter = true;
        } else {
            this.delimiter = e.target.value;
            this.other_delimiter = false;
        }
        this.parseCsv();
        this.generateColumnNames();
        this.updateModel();
        this.render();
    },

    setOtherDelimiter: function() {
        this.$("input.delimiter[type=radio]").prop("checked", false);
        var otherRadio = this.$("input#delimiter_other");
        otherRadio.prop("checked", true);
        otherRadio.click();
    }
});

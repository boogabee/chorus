chorus.dialogs.CreateDirectoryExternalTableFromHdfs = chorus.dialogs.NewTableImportCSV.extend({
    constructorName: "CreateDirectoryExternalTableFromHdfs",
    title: t("hdfs.create_external.title"),
    loadingKey: "hdfs.create_external.creating",
    templateName: "create_directory_external_table_from_hdfs",
    includeHeader: false,

    events: {
        "change select" : "fetchSample"
    },

    setup: function() {
        this.options.model = this.collection && this.collection.at(0);
        this.options.csvOptions = this.options.csvOptions || {};

        this.model = this.options.model;
        this.csvOptions = this.options.csvOptions;

        this.setupCsvOptions();
        this.setupModel();

        $(document).one('reveal.facebox', _.bind(this.setupSelects, this));

        this._super("setup", arguments);
    },

    setupCsvOptions: function(){
        this.csvOptions.hasHeader = false;
        this.csvOptions.tableName = chorus.utilities.CsvParser.normalizeForDatabase(this.options.directoryName);
    },

    setupModel: function() {
        this.model.set({hdfsDataSourceId : this.collection.attributes.hdfsDataSource.id}, {silent: true});
        this.model.set({path: this.pathWithSlash() + this.model.get("name")}, {silent: true});
    },

    setupSelects: function() {
        chorus.styleSelect(this.$("select"));
    },

    postRender: function() {
        this._super("postRender", arguments);
        this.$("select").val(this.model.get("name"));
        this.$("input#" + this.pathType).prop("checked", true);
    },

    additionalContext: function() {
        var parentCtx = this._super("additionalContext", arguments);
        parentCtx.pattern = this.pattern;
        parentCtx.directions = new Handlebars.SafeString("<input type='text' class='hdfs' name='tableName' value='" + Handlebars.Utils.escapeExpression(this.model.get('tableName')) + "'/>");
        return parentCtx;
    },

    pathWithSlash: function() {
        var path = this.collection.attributes.path;
        return (path === "/") ? path : path + "/";
    },

    performValidation: function() {
        var parent_dialog_valid = this._super("performValidation", arguments);

        if(this.$("input[name='pathType']:checked").val() === "pattern") {
            var regexp_s = this.$("input[name='pattern']").val();

            regexp_s = regexp_s.replace(/\*/g, ".*");
            var regexp = new RegExp(regexp_s, "i");
            var result = regexp.test(this.model.get("name"));

            if (!result) {
                this.markInputAsInvalid(this.$("input[name='pattern']"), t("hdfs_data_source.create_external.validation.pattern"), true);
            }
            return result && parent_dialog_valid;
        }

        return parent_dialog_valid;
    },

    saved: function() {
        this.closeModal();
        chorus.toast("hdfs.create_external.success", {tableName: this.model.get('tableName'), workspaceName: this.model.get("workspaceName")});
        chorus.PageEvents.trigger("csv_import:started");
    },

    updateModel: function() {
        var $names = this.$(".column_name input:text");
        var tableName = this.$(".directions input:text").val();
        var columns = _.map($names, function(name, i) {
            var $name = $names.eq(i);
            return chorus.Mixins.dbHelpers.ensureDoubleQuoted($name.val());
        });

        this.tableName = this.$(".directions input:text").val();

        var pathType = this.$("input[name='pathType']:checked").val();
        var path = (pathType === "pattern") ? this.$("input[name='pattern']").val() : "*";

        this.model.set({
            fileType: "TEXT",
            pathType : pathType,
            workspaceId: this.options.workspaceId,
            workspaceName: this.options.workspaceName,
            columnNames: columns,
            tableName: chorus.utilities.CsvParser.normalizeForDatabase(tableName),
            delimiter: this.delimiter,
            hdfs_entry_id : this.options.hdfs_entry_id,
            file_pattern: path
        }, {silent : true});
    },

    fetchSample: function(e) {
        e && e.preventDefault();
        this.pathType = this.$("input[name='pathType']:checked").val();
        this.pattern = this.$("input[name='pattern']").val();
        this.resource = this.model = this.collection.find(function(modelSet) {
            return modelSet.get('name') === $(e.target).val();
        });

        this.setupCsvOptions();
        this.setupModel();

        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);

        this.model.fetch();
        this.model.set({hasHeader: false}, {silent: true});

        this.$(".import_data_grid").startLoading();

        this.listenTo(this.model, "loaded", function() {
            this.contents = this.model.get('contents');
            this.$(".import_data_grid").stopLoading();
            this.render();
            this.setupSelects();
        });
    }
});

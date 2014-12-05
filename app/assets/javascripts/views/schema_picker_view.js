//= require ./location_picker/base_view.js

chorus.views.SchemaPicker = chorus.views.LocationPicker.BaseView.extend({
    constructorName: "SchemaPickerView",
    templateName: "schema_picker",

    showAllDbDataSources: false,

    events: {
        "click .database a.new": "createNewDatabase",
        "click .database .cancel": "cancelNewDatabase",
        "click .schema a.new": "createNewSchema",
        "click .schema .cancel": "cancelNewSchema"
    },

    subviews: {
        ".data_source": "dataSourceView",
        ".database": "databaseView",
        ".schema": "schemaView"
    },

    buildSelectorViews: function() {
        this.schemaView = new chorus.views.LocationPicker.SchemaView({
            allowCreate: this.options.allowCreate
        });

        this.databaseView = new chorus.views.LocationPicker.DatabaseView({
            childPicker: this.schemaView,
            allowCreate: this.options.allowCreate
        });

        this.dataSourceView = new chorus.views.LocationPicker.DataSourceView({
            childPicker: this.databaseView,
            showAllDbDataSources: this.options.showAllDbDataSources || false,
            alwaysPickSchema: true
        });

        this.registerSubView(this.schemaView);
        this.registerSubView(this.databaseView);
        this.registerSubView(this.dataSourceView);
    },

    setSelectorViewDefaults: function() {

        this.databaseView.hide();
        this.schemaView.hide();

        var defaultSchema = this.options.defaultSchema;

        if (defaultSchema) {
            var schemaParent = defaultSchema.parent();
            var dataSource, database;

            if (schemaParent.parent) {
                database = schemaParent;
                dataSource = schemaParent.dataSource();
            } else {
                dataSource = schemaParent;
            }

            this.setSelection('dataSource', dataSource);
            database && this.setSelection('database', database);
            this.setSelection('schema', defaultSchema);

            this.dataSourceView.loading();
            database && this.databaseView.loading();
            this.schemaView.loading();
        } else {
            this.setSelection('dataSource', this.options.dataSource);
            this.setSelection('database', this.options.database);
        }

        if (this.dataSourceView.selection && !this.options.database) {
            var selection = this.dataSourceView.selection;
            if (selection.isSingleLevelSource()) {
                this.schemaView.fetchSchemas(selection);
            } else {
                this.databaseView.fetchDatabases(selection);
            }
        }

        if (this.databaseView.selection) {
            this.schemaView.fetchSchemas(this.databaseView.selection);
        }
    },

    postRender: function() {
        this.$('.loading_spinner').startLoading();
        this.$("input.name").bind("textchange", _.bind(this.triggerSchemaSelected, this));
    },

    createNewDatabase: function(e) {
        e.preventDefault();
        this.trigger("clearErrors");
        this.databaseView.createNew();
        this.schemaView.createNested();
    },

    createNewSchema: function(e) {
        e.preventDefault();
        this.trigger("clearErrors");
        this.schemaView.createNew();
    },

    cancelNewDatabase: function(e) {
        this.cancel(e, this.databaseView);
    },

    cancelNewSchema: function(e) {
        this.cancel(e, this.schemaView);
    },

    cancel: function(e, view) {
        e.preventDefault();
        view.collectionLoaded();
        this.triggerSchemaSelected();
    },

    schemaId: function() {
        var selectedSchema = this.schemaView.getSelectedSchema();
        return selectedSchema && selectedSchema.id;
    },

    getSelectedSchema: function() {
        return this.schemaView.selection;
    },

    getSelectedDatabase: function() {
        return this.databaseView.selection;
    },

    additionalContext: function() {
        return { options: this.options };
    },

    ready: function() {
        return this.schemaView.ready();
    }
});

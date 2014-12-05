chorus.views.LocationPicker.DatabaseView = chorus.views.LocationPicker.SelectorView.extend({
    templateName: "location_picker_database",
    constructorName: "LocationPickerDatabaseView",

    events: {
        "change select": "databaseSelected"
    },

    setup: function() {
        this._super('setup');
        this.loading();
    },

    additionalContext: function() {
        return {
            allowCreate: this.options.allowCreate
        };
    },

    parentSelected: function(dataSource) {
        this.clearSelection();
        this.childPicker && this.childPicker.clearSelection();
        if (dataSource && !dataSource.isSingleLevelSource()) {
            this.loading();
            this.fetchDatabases(dataSource);
        } else {
            this.hide();
            this.childPicker && this.childPicker.parentSelected(dataSource);
        }
    },

    onFetchFailed: function() {
        this.clearSelection();
    },

    fetchDatabases: function(selectedDataSource) {
        this.collection = selectedDataSource.databases();
        this.collection.fetchAllIfNotLoaded();
        this.listenTo(this.collection, "fetchFailed", this.fetchFailed);
        this.onceLoaded(this.collection, this.collectionLoaded);
    },

    databaseSelected: function() {
        this.trigger("clearErrors");
        var selectedDatabase = this.getSelectedDatabase();
        this.setSelection(selectedDatabase);
        this.trigger('change');
    },

    onSelection: function() {
        if (this.childPicker) {
            if (this.selection) {
                this.childPicker.parentSelected(this.selection);
            } else {
                this.childPicker.hide();
            }
        }
    },

    fieldValues: function() {
        var attrs = {};
        if(this.selection && this.selection.get('id')) {
            attrs.database = this.selection.get("id");
        } else if(this.selection && this.selection.get("name")) {
            attrs.databaseName = this.selection.get('name');
        } else {
            attrs.databaseName = this.$("input.name:visible").val();
        }
        return attrs;
    },

    getSelectedDatabase: function() {
        return this.collection && this.collection.get(this.$('select option:selected').val());
    },

    ready: function() {
        var attrs = this.fieldValues();
        return !!(attrs.database || attrs.databaseName);
    }
});

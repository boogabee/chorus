chorus.views.LocationPicker.SchemaView = chorus.views.LocationPicker.SelectorView.extend({
    templateName: "location_picker_schema",
    constructorName: "LocationPickerSchemaView",

    events: {
        "change select": "schemaSelected"
    },

    additionalContext: function() {
        return {
            allowCreate: this.options.allowCreate
        };
    },

    createNested: function() {
        this.clearSelection();
        this.setState(this.STATES.CREATE_NESTED);
        this.$("input.name").val(chorus.models.Schema.DEFAULT_NAME);
    },

    createNew: function() {
        this._super('createNew');
        this.$("input.name").val("");
    },

    onFetchFailed: function() {
        this.clearSelection();
    },

    onMissingSelection: function() {
        this.showErrorForMissingSchema();
    },

    showErrorForMissingSchema: function() {
        this.collection.serverErrors = {fields: {base: {SCHEMA_MISSING: {name: this.selection.name()}}}};
        this.trigger("error", this.collection);
    },

    parentSelected: function(parent) {
        this.clearSelection();
        if (parent) {
            this.loading();
            this.fetchSchemas(parent);
        }
    },

    fetchSchemas: function(selectedDatabase) {
        this.collection = selectedDatabase.schemas();
        if(!this.collection.loaded) { // TEST ME
            this.loading();
        }
        this.collection.fetchAllIfNotLoaded();
        this.listenTo(this.collection, "fetchFailed", this.fetchFailed);
        this.onceLoaded(this.collection, this.collectionLoaded);
    },

    schemaSelected: function() {
        this.trigger("clearErrors");
        this.selection = this.getSelectedSchema();
        this.trigger('change');
    },

    getSelectedSchema: function() {
        return this.collection && this.collection.get(this.$('select option:selected').val());
    },

    fieldValues: function() {
        if(this.selection) {
            return {schema: this.selection.get("id")};
        } else {
            return {schemaName: this.$("input.name:visible").val() };
        }
    },

    ready: function() {
        var attrs = this.fieldValues();
        return !!(attrs.schema || attrs.schemaName);
    }
});

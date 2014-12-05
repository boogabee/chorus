chorus.views.WorkFlowExecutionLocationPicker = chorus.views.LocationPicker.BaseView.extend({
    constructorName: 'WorkFlowExecutionLocationPicker',
    templateName: "execution_location_picker",

    events: {
        'click a.remove_source': 'remove'
    },

    subviews: {
        ".data_source": "dataSourceView",
        ".database": "databaseView"
    },

    remove: function (e) {
        e && e.preventDefault();
        this.trigger('remove', this);
        this.teardown();
    },

    additionalContext: function () {
        return this.options;
    },

    buildSelectorViews: function() {
        this.databaseView = new chorus.views.LocationPicker.DatabaseView();

        this.dataSourceView = new chorus.views.LocationPicker.DataSourceView({
            showAllDbDataSources: true,
            showHdfsDataSources: true,
            childPicker: this.databaseView
        });

        this.registerSubView(this.databaseView);
        this.registerSubView(this.dataSourceView);
    },

    setSelectorViewDefaults: function() {
        this.databaseView.hide();
        this.setSelection('dataSource', this.options.dataSource);
        this.setSelection('database', this.options.database);

        if(this.dataSourceView.selection && this.options.dataSource.databases) {
            this.databaseView.loading();
            this.databaseView.fetchDatabases(this.dataSourceView.selection);
        }
    },

    getSelectedDataSource: function() {
        return this.dataSourceView.selection;
    },

    getSelectedDatabase: function() {
        return this.databaseView.selection;
    },
    
    getSelectedLocation: function () {
        return this.isSingleLevelSource() ? this.getSelectedDataSource() : this.getSelectedDatabase();
    },

    ready: function() {
        return this._super('ready') || this.isSingleLevelSource();
    },

    isSingleLevelSource: function() {
        var selectedDataSource = this.getSelectedDataSource();
        return selectedDataSource && selectedDataSource.isSingleLevelSource();
    }
});

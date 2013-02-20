chorus.views.DataTab = chorus.views.DatabaseSidebarList.extend({
    constructorName: "DataTabView",
    templateName:"data_tab",
    useLoadingSection:true,

    subviews: {
        ".list_contents": "listview"
    },

    setup: function() {
        this._super("setup", arguments);
        this.focusSchema = this.schema;
    },

    postRender: function() {
        this._super('postRender', arguments);

        chorus.search({
            list: this.$('ul'),
            input: this.$('input.search'),
            onTextChange: _.debounce(_.bind(this.searchTextChanged, this), 400)
        });
    },

    additionalContext: function() {
        var ctx = this._super("additionalContext", arguments);
        ctx.isWorkspaceSchema = (this.schema && this.schema.get("id") === "workspaceSchema");
        ctx.error = this.collection && this.collection.serverErrors && this.collection.serverErrors.message;
        if (this.collection && this.collection.statusCode === 403 && this.schemas.statusCode === 200) {
            ctx.noCredentials = true;
            ctx.noCredentialsWarning = t('dataset.credentials.insufficient',
                {
                    dataSourceName: this.schema.database().instance().name(),
                    schemaName: this.schema.name()
                });
        }
        return ctx;
    },

    fetchResourceAfterSchemaSelected: function() {
        if (this.schema.get("id") === "workspaceSchema") {
            this.collection = new chorus.collections.WorkspaceDatasetSet([], {
                workspaceId: chorus.page.workspace.id,
                unsorted: true
            });
            this.collection.sortAsc("objectName");

            if (this.focusSchema) {
                this.collection.attributes.database = this.focusSchema.database();
                this.collection.attributes.databaseName = this.focusSchema.database().name();
            }

            this.collection.fetch();
        } else {
            this.collection = this.schema.datasets();
            this.collection.fetchIfNotLoaded();
        }

        this.bindings.add(this.collection, "searched", this.onSearchComplete);
        this.listview && this.listview.teardown();
        this.listview = new chorus.views.DataTabDatasetList({collection: this.collection});
        this.registerSubView(this.listview);

        this.bindings.add(this.collection, 'serverResponded', this.render);
        this.bindings.add(this.listview, "fetch:more", this.fetchMoreDatasets);
    },

    setSchemaToCurrentWorkspace: function() {
        this.schema = new chorus.models.Schema({id: "workspaceSchema", name: t("database.sidebar.this_workspace")});
    },

    fetchMoreDatasets: function(e) {
        e && e.preventDefault();
        var next = parseInt(this.collection.pagination.page, 10) + 1;
        this.collection.fetchPage(next, { update: true, remove: false , success: _.bind(this.datasetsAdded, this) });
    },

    datasetsAdded: function() {
        this.listview.render();
        this.postRender();
    },

    searchTextChanged: function(e) {
        this.collection.search($(e.target).val());
    },

    onSearchComplete: function() {
        this.listview.render();
        this.postRender();
    },

    setSchema:function(schema) {
        this._super("setSchema", arguments);
        this.focusSchema = schema;
    },

    displayLoadingSection: function () {
        return this.schema && !(this.collection && (this.collection.loaded || this.collection.serverErrors));
    }
});